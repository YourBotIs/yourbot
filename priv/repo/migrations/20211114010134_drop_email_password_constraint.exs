defmodule YourBot.Repo.Migrations.DropEmailPasswordConstraint do
  use Ecto.Migration

  def change do
    # alter table users alter column email drop not null;
    alter table(:users) do
      remove :hashed_password
    end
  end
end
