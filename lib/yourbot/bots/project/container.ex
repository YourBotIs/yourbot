defmodule YourBot.Bots.Project.Container do
  @moduledoc """
  Container object for archiving all the required data
  for the sandbox runtime execute and monitor.
  """
  use Ecto.Schema

  schema "projects" do
    belongs_to :bot, YourBot.Bots.Bot
    field :uuid, :binary_id, null: false
    timestamps()
  end

  def initialize(%YourBot.Bots.Project.Container{} = container) do
    YourBot.Bots.Project.Repo.with_repo(container, fn %{pid: pid} ->
      _ =
        Ecto.Migrator.run(YourBot.Bots.Project.Repo, :up,
          all: true,
          dynamic_repo: pid,
          log: :debug,
          log_migrations_sql: :debug,
          log_migrator_sql: :debug
        )
    end)

    {:ok, container}
  end

  def rollback(%YourBot.Bots.Project.Container{} = container) do
    YourBot.Bots.Project.Repo.with_repo(container, fn %{pid: pid} ->
      _ =
        Ecto.Migrator.run(YourBot.Bots.Project.Repo, :down,
          step: 1,
          dynamic_repo: pid,
          log: :debug,
          log_migrations_sql: :debug,
          log_migrator_sql: :debug
        )
    end)

    {:ok, container}
  end

  def path(%YourBot.Bots.Project.Container{uuid: uuid}) do
    Path.expand(Path.join(YourBot.Bots.Project.storage_dir(), "#{uuid}.sqlite3"))
  end
end
