defmodule YourBot.Bots.EnvironmentVariable do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bot_environment_variables" do
    belongs_to :bot, YourBot.Bots.Bot
    field :key, :string, null: false
    field :value, :string, null: false, redact: true
    timestamps()
  end

  def changeset(env, attrs) do
    env
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
    |> unique_constraint([:bot_id, :key])
  end
end
