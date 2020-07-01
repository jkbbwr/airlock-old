defmodule Airlock.Auth do
  def fingerprint(key) do
    :public_key.ssh_encode([{key, []}], :auth_keys)
  end

  def load_key(path) do
    File.read!(path)
    |> :public_key.pem_decode
    |> List.first()
    |> :public_key.pem_entry_decode
  end
end