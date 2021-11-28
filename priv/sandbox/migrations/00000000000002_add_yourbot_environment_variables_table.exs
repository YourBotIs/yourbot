defmodule YourBot.Repo.Migrations.AddEnvironmentVariablesTable do
  use Ecto.Migration

  def change do
    create table(:yourbot_environment_variables) do
      add :project_id, references(:yourbot_project), null: false
      add :key, :string, null: false
      add :value, :string, null: false
      timestamps()
    end

    create unique_index(:yourbot_environment_variables, [:project_id, :key])
  end
end
