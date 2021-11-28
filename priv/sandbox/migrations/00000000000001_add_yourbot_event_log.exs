defmodule YourBot.Bots.DB.Repo.Migrations.AddYourbotEventLog do
  use Ecto.Migration

  def change do
    create table(:yourbot_event_log) do
      add :project_id, references(:yourbot_project), null: false
      add :name, :string
      add :content, :string
      timestamps()
    end
  end
end
