defmodule Airlock.Repo do
  use Ecto.Repo,
    otp_app: :airlock,
    adapter: Ecto.Adapters.Postgres
end
