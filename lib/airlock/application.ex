defmodule Airlock.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Airlock.Repo,
      # Start the registry,
      Airlock.Registry,
      # SSH server
      Airlock.Server,
      # Start the Telemetry supervisor
      AirlockWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Airlock.PubSub},
      # Start the Endpoint (http/https)
      AirlockWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Airlock.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    AirlockWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
