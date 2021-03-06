defmodule YourBot.Bots.Bot do
  @moduledoc "represents a discord bot"

  use Ecto.Schema
  import Ecto.Changeset

  schema "bots" do
    has_one :project, YourBot.Bots.Project.Container
    field :name, :string, null: false
    field :token, :string, null: false, redact: true
    field :application_id, Snowflake, null: false
    field :public_key, :string, null: false
    field :deploy_status, Ecto.Enum, values: [:live, :stop, :edit, :error]
    field :uptime_status, Ecto.Enum, values: [:boot, :up, :down], virtual: true
    timestamps()
  end

  def changeset(bot, attrs \\ %{}) do
    bot
    |> cast(attrs, [:name, :token, :application_id, :public_key])
    |> validate_required([:name, :token, :application_id, :public_key])
    |> unique_constraint([:name])
    |> unique_constraint([:application_id])
  end

  def deploy_changeset(bot, status) do
    bot
    |> cast(%{deploy_status: status}, [:deploy_status])
    |> validate_required([:deploy_status])
  end

  def code_template(bot, user) do
    file = Application.app_dir(:yourbot, ["priv", "sandbox", "client.py.eex"])
    today = Date.utc_today()

    EEx.eval_file(file,
      bot: bot,
      user: user,
      month: Calendar.strftime(today, "%B"),
      year: Calendar.strftime(today, "%Y"),
      client_object: "MyClient"
    )
  end
end
