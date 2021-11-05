defmodule YourBot.Bots.BotUser do
  use Ecto.Schema

  schema "bot_users" do
    belongs_to :bot, YourBot.Bots.Bot
    belongs_to :user, YourBot.Accounts.User
    timestamps()
  end
end
