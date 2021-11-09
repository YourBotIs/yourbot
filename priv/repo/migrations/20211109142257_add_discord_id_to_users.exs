defmodule YourBot.Repo.Migrations.AddDiscordIdToUsers do
  use Ecto.Migration

  def change do
    create table(:discord_oauths) do
      add :discord_user_id, :binary, null: false
      add :avatar, :string, null: false
      add :username, :string, null: false
      add :discriminator, :string, null: false
    end

    create unique_index(:discord_oauths, [:discord_user_id])

    alter table(:users) do
      add :discord_oauth_id, references(:discord_oauths), on_delete: :delete_all
    end

    create unique_index(:users, [:id, :discord_oauth_id])
  end
end
