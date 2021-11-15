defmodule YourBot.Repo.Migrations.AddStatusToBots do
  use Ecto.Migration

  def change do
    execute(
      # up
      "CREATE TYPE bot_deploy_status AS ENUM ('live', 'stop', 'error', 'edit')",
      # down
      "DROP TYPE bot_status"
    )

    alter table(:bots) do
      add :deploy_status, :bot_deploy_status, default: "stop", null: false
    end

    create index(:bots, :deploy_status)
  end
end
