defmodule YourBot.Accounts.DiscordOauth do
  use Ecto.Schema
  import Ecto.Changeset

  schema "discord_oauths" do
    has_one :user, YourBot.Accounts.User
    field :discord_user_id, Snowflake
    field :avatar, :string
    field :username, :string
    field :discriminator, :string
  end

  def changeset(discord_oauth, attrs \\ %{}) do
    discord_oauth
    |> cast(attrs, [:discord_user_id, :avatar, :username, :discriminator])
    |> validate_required([:discord_user_id, :avatar, :username, :discriminator])
    |> unique_constraint(:discord_user_id)
  end
end
