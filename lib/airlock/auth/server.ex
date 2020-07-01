defmodule Airlock.Auth.Server do
  @behaviour :ssh_server_key_api
  require Logger

  @impl true
  def host_key(:"ssh-ed25519", _options) do
    {:ok, Airlock.Auth.load_key("ed25519_host_key")}
  end

  @impl true
  def host_key(_algo, _options) do
    {:error, :unsupported_algo}
  end

  @impl true
  def is_auth_key(public_key, user, _options) do
    [algo, fingerprint] = String.split(Airlock.Auth.fingerprint(public_key))
    allowed = Airlock.Session.key_is_allowed?(to_string(user), {algo, fingerprint})
    Logger.debug("Algo=#{algo} Fingerprint=#{fingerprint} Allowed=#{allowed}")
    allowed
  end
end