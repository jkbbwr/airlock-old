defmodule Airlock.Server do
  require Logger
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state, {:continue, :start_ssh_daemon}}
  end

  @impl true
  def handle_continue(:start_ssh_daemon, state) do
    port = Keyword.get(state, :port, 2222)
    Logger.info("Starting SSH daemon on port #{port}")
    {:ok, _pid} = :ssh.daemon(
      port,
      auth_methods: 'publickey',
      key_cb: Airlock.Auth.Server,
      ssh_cli: {Airlock.ServerChannel, [%{}]},
    )
    Logger.info("SSH daemon is up!")
    {:noreply, state}
  end
end
