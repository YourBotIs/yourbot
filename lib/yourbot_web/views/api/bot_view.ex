defmodule YourBotWeb.BotsView do
  use YourBotWeb, :view

  def render("index.json", %{bots: bots}) do
    %{data: render_many(bots, YourBotWeb.BotsView, "show.json")}
  end

  def render("show.json", %{bots: bot}) do
    %{data: render_one(bot, YourBotWeb.BotsView, "bot.json")}
  end

  def render("bot.json", %{bots: bot}) do
    %{
      id: bot.id,
      name: bot.name,
      token: bot.token,
      application_id: bot.application_id,
      public_key: bot.public_key,
      code: bot.code
    }
  end

  def render("error.json", %{changeset: changeset}) do
    errors = Map.new(changeset.errors, fn {name, {error, _}} -> {name, error} end)
    %{errors: errors}
  end
end
