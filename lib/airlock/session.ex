defmodule Airlock.Session do
  require Logger
  use GenServer

  def create(name, required_participants, allowed_keys, server_details) when is_list(allowed_keys) do
    Airlock.Session.start_link(
      name,
      %{
        name: name,
        required_participants: required_participants,
        allowed_keys: MapSet.new(allowed_keys),
        clients: [],
        outgoing_client: nil,
        server_details: server_details
      }
    )
  end

  def start_link(name, state) do
    GenServer.start_link(__MODULE__, state, name: Airlock.Registry.via(name))
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Lookup the key in the session identified by the name.
  """
  def key_is_allowed?(name, key) do
    case Airlock.Registry.lookup(name) do
      [{pid, _}] -> GenServer.call(pid, {:key_allowed, key})
      [] -> false
    end
  end

  def join(name) when is_list(name), do: join(to_string(name))
  def join(name) do
    case Airlock.Registry.lookup(name) do
      [{pid, _}] -> GenServer.call(pid, :join)
      [] -> :failed
    end
  end

  def send_into(name, data) when is_list(name), do: send_into(to_string(name), data)
  def send_into(name, data) do
    case Airlock.Registry.lookup(name) do
      [{pid, _}] -> GenServer.cast(pid, {:send_into, data})
      [] -> :failed
    end
  end

  def send_out(name, data) when is_list(name), do: send_out(to_string(name), data)
  def send_out(name, data) do
    case Airlock.Registry.lookup(name) do
      [{pid, _}] -> GenServer.cast(pid, {:send_out, data})
      [] -> :failed
    end
  end

  @impl true
  def handle_cast({:send_into, data}, state) do
    Airlock.ClientChannel.send(state.outgoing_client, data)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_out, data}, state) do
    Logger.debug("#{inspect state.clients}")
    Enum.each(
      state.clients,
      fn client ->
        Logger.debug("Sending out some data to #{inspect client} #{inspect data}")
        Airlock.ServerChannel.send(client, data)
      end
    )
    {:noreply, state}
  end

  @impl true
  def handle_call({:key_allowed, key}, _from, state) do
    {:reply, MapSet.member?(state.allowed_keys, key), state}
  end

  @impl true
  def handle_call(:join, {from, _ref}, state) do
    {:reply, :ok, update_in(state, [:clients], &([from] ++ &1)), {:continue, :check_ready}}
  end

  @impl true
  def handle_continue(:connect_to_server, %{outgoing_client: outgoing_client} = state) when is_nil(outgoing_client) do
    %{hostname: hostname, port: port, username: username} = state.server_details
    {:ok, conn} = Airlock.ClientChannel.connect(hostname, port, username, state.name)
    Airlock.ClientChannel.pty(conn, [])
    Airlock.ClientChannel.shell(conn)

    Enum.each(state.clients, fn client ->
      Airlock.ServerChannel.clear(client)
    end)

    {:noreply, %{state | outgoing_client: conn}}
  end

  @impl true
  def handle_continue(:connect_to_server, state) do
    {:noreply, state}
  end

  @impl true
  def handle_continue(:check_ready, %{clients: clients, required_participants: required_participants} = state)
      when length(clients) >= required_participants do
    Enum.each(
      state.clients,
      fn client ->
        Airlock.ServerChannel.update_ready(client, :ready)
      end
    )
    {:noreply, state, {:continue, :connect_to_server}}
  end

  @impl true
  def handle_continue(:check_ready, state) do
    Enum.each(
      state.clients,
      fn client ->
        Airlock.ServerChannel.update_ready(client, {:need_more, Enum.count(state.clients), state.required_participants})
      end
    )
    {:noreply, state}
  end
end
