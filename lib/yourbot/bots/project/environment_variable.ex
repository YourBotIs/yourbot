defmodule YourBot.Bots.Project.EnvironmentVariable do
  use Ecto.Schema
  import Ecto.Changeset

  schema "yourbot_environment_variables" do
    belongs_to :project, YourBot.Bots.Project
    field :key, :string, null: false
    field :value, :string, null: false, redact: true
    timestamps()
  end

  def changeset(env, attrs) do
    env
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
    |> unique_constraint([:project_id, :key])
  end
end
