defmodule YourBot.Repo.Migrations.AddBotFilesTable do
  use Ecto.Migration

  def change do
    create table(:yourbot_files) do
      add :project_id, references(:yourbot_project), null: false
      add :uuid, :uuid, null: false
      add :name, :string, null: false
      add :content, :blob, null: false
      timestamps()
    end

    create unique_index(:yourbot_files, [:project_id, :name])
    create unique_index(:yourbot_files, [:project_id, :uuid])
  end
end
