defmodule YourBotWeb.UsersView do
  use YourBotWeb, :view

  def render("show.json", %{discord_oauth: discord_oauth}) do
    %{
      data:
        render_one(discord_oauth, YourBotWeb.UsersView, "discord_oauth.json", as: :discord_oauth)
    }
  end

  def render("discord_oauth.json", %{discord_oauth: discord_oauth}) do
    %{
      discord_user_id: discord_oauth.discord_user_id,
      avatar: discord_oauth.avatar,
      username: discord_oauth.username,
      discriminator: discord_oauth.discriminator
    }
  end

  def render("error.json", %{changeset: changeset}) do
    errors = Map.new(changeset.errors, fn {name, {error, _}} -> {name, error} end)
    %{errors: errors}
  end
end
