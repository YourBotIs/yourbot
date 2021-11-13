defmodule YourBotWeb.UsersView do
  use YourBotWeb, :view

  def render("show.json", %{users: user}) do
    %{data: render_one(user, YourBotWeb.UsersView, "user.json")}
  end

  def render("user.json", %{users: %{discord_oauth: discord_oauth}}) do
    %{
      discord_user_id: discord_oauth.discord_user_id,
      avatar: discord_oauth.avatar,
      username: discord_oauth.username,
      discriminator: discord_oauth.discriminator
    }
  end
end
