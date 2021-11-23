defmodule YourBotWeb.PageController do
  use YourBotWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def tos(conn, _params) do
    conn
    |> put_status(:ok)
    |> render("tos.html")
  end

  def privacy_policy(conn, _params) do
    conn
    |> put_status(:ok)
    |> render("privacy-policy.html")
  end
end
