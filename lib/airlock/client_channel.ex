defmodule Airlock.ClientChannel do
  @behaviour :ssh_client_channel
  require Logger

  def send(pid, data) do
    GenServer.cast(pid, {:send, data})
  end

  def pty(pid, options) do
    GenServer.cast(pid, {:pty, options})
  end

  def shell(pid) do
    GenServer.cast(pid, :shell)
  end

  def connect(hostname, port, username, session_name) do
    {:ok, conn} = :ssh.connect(
      hostname,
      port,
      user: username,
      key_cb: Airlock.Auth.Client,
      auth_methods: 'publickey'
    )
    Airlock.ClientChannel.start_link(session_name, conn)
  end

  def start_link(session_name, connection) do
    {:ok, channel} = :ssh_connection.session_channel(connection, :infinity)
    :ssh_client_channel.start_link(
      connection,
      channel,
      Airlock.ClientChannel,
      %{
        connection: connection,
        channel: channel,
        connection_info: :ssh.connection_info(connection),
        session_name: session_name
      }
    )
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(msg, _from, state) do
    Logger.debug("call #{inspect msg}")
    {:reply, :unknown_call, state}
  end

  @impl true
  def handle_cast({:send, data}, state) do
    Logger.debug("Sending some data in")
    :ssh_connection.send(state.connection, state.channel, data)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:pty, options}, state) do
    Logger.debug("I asked for a pty")
    :success = :ssh_connection.ptty_alloc(state.connection, state.channel, options)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:shell, state) do
    Logger.debug("I asked for a shell")
    :ok = :ssh_connection.shell(state.connection, state.channel)
    {:noreply, state}
  end

  @impl true
  def handle_cast(msg, state) do
    Logger.debug("cast #{inspect msg}")
    {:noreply, state}
  end

  @impl true
  def handle_msg(msg, state) do
    Logger.debug("client msg #{inspect msg}")
    {:ok, state}
  end

  @impl true
  def handle_ssh_msg({:ssh_cm, _connection, {:data, _channel, _data_type_code, data}}, state) do
    :ok = Airlock.Session.send_out(state.session_name, data)
    {:ok, state}
  end

  @impl true
  def handle_ssh_msg(msg, state) do
    Logger.debug("client ssh_msg #{inspect msg}")
    {:ok, state}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.debug("terminated because #{inspect reason}")
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end
end
