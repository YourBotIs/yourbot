defmodule YourBot.Repo.Migrations.CreateBotsTable do
  use Ecto.Migration

  def change do
    create table(:bots) do
      add :name, :citext, null: false
      add :token, :string, null: false
      add :application_id, :binary, null: false
      add :public_key, :string, null: false
      timestamps()
    end

    create table(:bot_users) do
      add :bot_id, references(:bots), null: false
      add :user_id, references(:users), null: false
      timestamps()
    end

    create unique_index(:bots, [:name])
    create unique_index(:bots, [:application_id])
    create unique_index(:bot_users, [:bot_id, :user_id])
  end
end
