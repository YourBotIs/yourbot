defmodule YourBot.Repo do
  use Ecto.Repo,
    otp_app: :yourbot,
    adapter: Ecto.Adapters.Postgres
end
