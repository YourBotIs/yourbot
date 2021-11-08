defmodule YourBotWeb.BotLiveTest do
  use YourBotWeb.FeatureCase
  import YourBot.AccountsFixtures
  import YourBot.BotFixtures
  import YourBotWeb.LoginPage, only: [login: 1]

  setup [:setup_user, :login]

  feature "create bot", %{session: session} do
    attrs = valid_bot_attrs()
    @endpoint.subscribe("crud:bots")

    session
    |> visit(Routes.bot_url(@endpoint, :index))
    |> click(css("[role='create_bot']"))
    |> fill_in(css("[role='bot_name_input']"), with: attrs[:name])
    |> fill_in(css("[role='bot_token_input']"), with: attrs[:token])
    |> fill_in(css("[role='bot_application_id_input']"), with: attrs[:application_id])
    |> fill_in(css("[role='bot_public_key_input']"), with: attrs[:public_key])
    |> click(css("[role='bot_submit']"))
    |> assert_has(css("[role='select_bot']", text: attrs[:name]))

    assert_received %Phoenix.Socket.Broadcast{event: "insert"}
  end
end
