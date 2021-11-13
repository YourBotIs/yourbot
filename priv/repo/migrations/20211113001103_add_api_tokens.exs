defmodule YourBot.Repo.Migrations.AddApiTokens do
  use Ecto.Migration

  def change do
    create table(:api_tokens) do
      add :user_id, references(:users), null: false
      add :token, :binary, null: false
    end

    create index(:api_tokens, [:user_id, :token])
  end
end
