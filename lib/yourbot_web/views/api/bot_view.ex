defmodule YourBotWeb.BotsView do
  use YourBotWeb, :view

  def render("index.json", %{bots: bots}) do
    %{data: render_many(bots, YourBotWeb.BotsView, "bot.json")}
  end

  def render("index.json", %{events: events}) do
    %{data: render_many(events, YourBotWeb.BotsView, "event.json", as: :event)}
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
      code: bot.code,
      deploy_status: bot.deploy_status
    }
  end

  def render("event.json", %{event: event}) do
    %{
      name: event.name,
      content: event.content,
      inserted_at: event.inserted_at,
      updated_at: event.updated_at
    }
  end

  def render("error.json", %{changeset: changeset}) do
    errors = Map.new(changeset.errors, fn {name, {error, _}} -> {name, error} end)
    %{errors: errors}
  end
end
