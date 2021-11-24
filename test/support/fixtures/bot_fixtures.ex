defmodule YourBot.BotFixtures do
  alias YourBot.Bots
  import YourBot.UniqueData
  import ExUnit.CaptureIO

  def valid_bot_attrs(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_name("bot"),
      token: unique_name("token"),
      application_id: unique_id(),
      public_key: unique_name("public_key")
    })
  end

  # capture_io here because upon bot creation,
  # an ecto repo is dynamically started and migrated for the bot.
  # this creates compiler warnings because modules are being reloaded
  def bot_fixture(user, attrs \\ %{}) do
    capture_io(:stderr, fn ->
      {:ok, bot} = Bots.create_bot(user, valid_bot_attrs(attrs))
      send(self(), {:block_result, bot})
    end)

    receive do
      {:block_result, bot} -> bot
    after
      0 ->
        raise "Timeout creating bot"
    end
  end

  def setup_bot(%{user: user} = env) do
    bot = bot_fixture(user)
    Map.put(env, :bot, bot)
  end
end
