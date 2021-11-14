defmodule YourBotWeb.UserSessionController do
  use YourBotWeb, :controller

  alias YourBotWeb.UserAuth

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
