defmodule YourBot.Repo.Migrations.AddBotFilesTable do
  use Ecto.Migration

  def change do
    create table(:bot_files) do
      add :bot_id, references(:bots), null: false
      add :uuid, :uuid, default: fragment("uuid_generate_v4()"), null: false
      add :name, :citext, null: false
      timestamps()
    end

    create unique_index(:bot_files, [:bot_id, :name])
  end
end
