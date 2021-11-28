defmodule YourBot.Repo.Migrations.AddProjectsTable do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"", ""

    create table("projects") do
      add :bot_id, references(:bots), null: false
      add :uuid, :uuid, default: fragment("uuid_generate_v4()"), null: false
      timestamps()
    end

    create unique_index(:projects, :bot_id)
  end
end
