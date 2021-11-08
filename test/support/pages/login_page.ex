defmodule YourBotWeb.LoginPage do
  @endpoint YourBotWeb.Endpoint
  alias YourBotWeb.Router.Helpers, as: Routes
  use Wallaby.DSL
  import Wallaby.Query

  def login(%{user: user, session: session}) do
    session
    |> visit(Routes.user_session_path(@endpoint, :new))
    |> fill_in(css("[role='login_email_input']"), with: user.email)
    |> fill_in(css("[role='login_password_input']"), with: user.password)
    |> click(css("[role='login_submit']"))

    :ok
  end
end
