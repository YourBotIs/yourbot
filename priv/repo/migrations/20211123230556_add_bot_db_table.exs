defmodule YourBot.Repo.Migrations.AddBotDbTable do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"", ""

    create table("bot_dbs") do
      add :bot_id, references(:bots), null: false
      add :uuid, :uuid, default: fragment("uuid_generate_v4()"), null: false
      timestamps()
    end

    create unique_index(:bot_dbs, :bot_id)
  end
end
