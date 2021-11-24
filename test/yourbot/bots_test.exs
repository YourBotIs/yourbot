defmodule YourBot.BotsTest do
  use YourBot.DataCase
  import YourBot.AccountsFixtures
  import YourBot.BotFixtures
  import YourBot.UniqueData
  import ExUnit.CaptureIO
  alias YourBot.Bots

  setup [:setup_user, :setup_discord_oauth]

  test "create bot", %{user: user} do
    @endpoint.subscribe("crud:bots")
    attrs = valid_bot_attrs()
    # capture_io here for the same reason as botfixtures. See that for more info
    capture_io(:stderr, fn ->
      {:ok, bot} = Bots.create_bot(user, attrs)
      send(self(), {:block_result, bot})
    end)

    assert_received {:block_result, bot}

    assert_received %Phoenix.Socket.Broadcast{
      topic: "crud:bots",
      event: "insert",
      payload: %{new: ^bot}
    }
  end

  setup [:setup_user, :setup_discord_oauth, :setup_bot]

  test "delete bot", %{bot: bot} do
    @endpoint.subscribe("crud:bots")
    assert {:ok, bot} = Bots.delete_bot(bot)

    assert_received %Phoenix.Socket.Broadcast{
      topic: "crud:bots",
      event: "delete",
      payload: %{old: ^bot}
    }
  end

  test "update bot", %{bot: bot} do
    @endpoint.subscribe("crud:bots")
    new_name = unique_name("bot-update")
    assert {:ok, updated_bot} = Bots.update_bot(bot, %{name: new_name})

    assert_received %Phoenix.Socket.Broadcast{
      topic: "crud:bots",
      event: "update",
      payload: %{old: ^bot, new: ^updated_bot}
    }
  end
end
