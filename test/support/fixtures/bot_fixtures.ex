defmodule YourBot.BotFixtures do
  alias YourBot.Bots
  import YourBot.UniqueData

  def valid_bot_attrs(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_name("bot"),
      token: unique_name("token"),
      application_id: unique_id(),
      public_key: unique_name("public_key")
    })
  end

  def bot_fixture(user, attrs \\ %{}) do
    {:ok, bot} = Bots.create_bot(user, valid_bot_attrs(attrs))
    bot
  end

  def setup_bot(%{user: user} = env) do
    bot = bot_fixture(user)
    Map.put(env, :bot, bot)
  end
end
