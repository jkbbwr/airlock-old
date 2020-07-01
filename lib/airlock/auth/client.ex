defmodule Airlock.Auth.Client do
  @behaviour :ssh_client_key_api

  def add_host_key(hostnames, public_host_key, options) do
    :ok
  end

  def is_host_key(key, host, algo, options) do
    true
  end

  def user_key(:"ssh-rsa", _options) do
    {:ok, Airlock.Auth.load_key("demo_local_key")}
  end

  @impl true
  def user_key(algo, options) do
    {:error, :not_supported}
  end
end
