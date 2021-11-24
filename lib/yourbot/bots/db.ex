defmodule YourBot.Bots.DB do
  use Ecto.Schema
  alias YourBot.Bots.DB.Repo

  schema "bot_dbs" do
    belongs_to :bot, YourBot.Bots.Bot
    field :uuid, :binary_id, null: false
    timestamps()
  end

  def initialize(%YourBot.Bots.DB{} = db) do
    Repo.with_repo(path(db), fn %{pid: pid} ->
      _ = Ecto.Migrator.run(Repo, :up, all: true, dynamic_repo: pid)
    end)
  end

  def path(%YourBot.Bots.DB{uuid: uuid}) do
    Path.join(storage_dir(), "#{uuid}.sqlite3")
  end

  def storage_dir do
    Application.get_env(:yourbot, __MODULE__)[:storage_dir]
  end
end
