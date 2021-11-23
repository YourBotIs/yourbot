defmodule YourBot.Repo.Migrations.AddEnvironmentVariablesTable do
  use Ecto.Migration

  def change do
    create table(:bot_environment_variables) do
      add :bot_id, references(:bots), null: false
      add :key, :string, null: false
      add :value, :string, null: false
      timestamps()
    end

    create unique_index(:bot_environment_variables, [:bot_id, :key])
  end
end
