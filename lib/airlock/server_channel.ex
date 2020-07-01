defmodule Airlock.ServerChannel do
  @behaviour :ssh_server_channel
  require Logger

  def update_ready(pid, update) do
    GenServer.cast(pid, update)
  end

  def send(pid, data) do
    GenServer.cast(pid, {:send, data})
  end

  def clear(pid) do
    GenServer.cast(pid, :clear)
  end

  @impl true
  def init([state]) do
    {:ok, state}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.debug("terminated because #{inspect reason}")
  end

  def handle_cast(:clear, state) do
    :ssh_connection.send(state.connection, state.channel, [IO.ANSI.clear(), IO.ANSI.home()])
    {:noreply, state}
  end

  def handle_cast(:ready, state) do
    :ssh_connection.send(
      state.connection,
      state.channel,
      [
        IO.ANSI.cursor(3, 0),
        "All users connected!"
      ]
    )
    {:noreply, %{state | lock_input: false}}
  end

  def handle_cast({:need_more, current, total}, state) do
    :ssh_connection.send(
      state.connection,
      state.channel,
      [
        IO.ANSI.cursor(2, 0),
        "Waiting for connections. (#{current}/#{total})"
      ]
    )
    {:noreply, state}
  end

  def handle_cast({:send, data}, state) do
    Logger.debug("Sending data out to the connection")
    :ssh_connection.send(state.connection, state.channel, data)
    {:noreply, state}
  end

  def handle_cast(msg, state) do
    Logger.debug("#{inspect msg}")
    {:noreply, state}
  end

  @impl true
  def handle_msg({:ssh_channel_up, channel, connection}, state) do
    Logger.debug("Client brought up a channel #{channel}")
    connection_info = :ssh.connection_info(connection)

    state = state
            |> Map.put(:channel, channel)
            |> Map.put(:connection, connection)
            |> Map.put(:lock_input, true)
            |> Map.put(:connection_info, connection_info)

    :ssh_connection.send(
      connection,
      channel,
      [
        IO.ANSI.clear(),
        IO.ANSI.home(),
        "Welcome to the airlock session #{state.connection_info[:user]}"
      ]
    )

    :ok = Airlock.Session.join(state.connection_info[:user])

    {:ok, state}
  end

  @impl true
  def handle_msg(msg, state) do
    Logger.debug("msg #{inspect msg}")
    {:ok, state}
  end

  @impl true
  def handle_ssh_msg({:ssh_cm, connection, {:pty, channel, want_reply, _options}}, state) do
    Logger.debug("Client asked for PTY and I said :success")
    :ssh_connection.reply_request(connection, want_reply, :success, channel)
    {:ok, state}
  end

  @impl true
  def handle_ssh_msg({:ssh_cm, connection, {:shell, channel, want_reply}}, state) do
    Logger.debug("Client asked for a shell and I said :success")
    :ssh_connection.reply_request(connection, want_reply, :success, channel)
    {:ok, state}
  end

  @impl true
  def handle_ssh_msg({:ssh_cm, _connection, {:data, channel, _data_type, <<3>>}}, %{lock_input: true} = state) do
    # Handle CTRL+D
    {:stop, channel, state}
  end

  @impl true
  def handle_ssh_msg({:ssh_cm, _connection, {:data, channel, _data_type, <<4>>}}, %{lock_input: true} = state) do
    # Handle CTRL+D
    {:stop, channel, state}
  end

  @impl true
  def handle_ssh_msg(
        {:ssh_cm, _connection, {:data, _channel, _data_type_code, _data}},
        %{locked_input: true} = state
      ) do
    # Input is locked.
    {:ok, state}
  end

  @impl true
  def handle_ssh_msg({:ssh_cm, _connection, {:data, _channel, _data_type_code, data}}, state) do
    # input is unlocked we must be in a connected state.
    Airlock.Session.send_into(state.connection_info[:user], data)
    {:ok, state}
  end

  @impl true
  def handle_ssh_msg(msg, state) do
    Logger.debug("ssh_msg #{inspect msg}")
    {:ok, state}
  end
end
