defmodule YourBot.Bots.DB.Repo do
  use Ecto.Repo,
    otp_app: :yourbot,
    adapter: Ecto.Adapters.SQLite3

  alias YourBot.Bots.DB.Repo

  def with_repo(database, fun) when is_binary(database) do
    default_dynamic_repo = Repo.get_dynamic_repo()

    {:ok, pid} =
      Repo.start_link(
        name: nil,
        database: database,
        pool_size: 1
      )

    try do
      Repo.put_dynamic_repo(pid)
      fun.(%{pid: pid, repo: Repo})
    after
      Repo.put_dynamic_repo(default_dynamic_repo)
      Supervisor.stop(pid)
    end
  end
end
