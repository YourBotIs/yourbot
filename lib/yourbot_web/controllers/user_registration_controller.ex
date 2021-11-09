defmodule YourBotWeb.UserRegistrationController do
  use YourBotWeb, :controller

  alias YourBot.Accounts
  alias YourBot.Accounts.{User, DiscordOauth}
  alias YourBotWeb.UserAuth

  def new(conn, %{"discord_oauth" => discord_oauth_params}) do
    discord_oauth_params =
      put_in(discord_oauth_params, ["discord_user_id"], discord_oauth_params["id"])

    case Accounts.create_discord_oauth(discord_oauth_params) do
      {:error, %{valid?: false} = _discord_oauth_changeset} ->
        changeset = Accounts.change_user_registration(%User{})

        conn
        |> put_flash(:error, "Could not log in with discord")
        |> render("new.html", changeset: changeset, discord_oauth: %DiscordOauth{})

      {:ok, discord_oauth} ->
        changeset =
          Accounts.change_user_registration(%User{}, %{email: discord_oauth_params["email"]})

        conn
        |> put_flash(:info, "Please create a password")
        |> render("new.html", changeset: changeset, discord_oauth: discord_oauth)
    end
  end

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset, discord_oauth: %DiscordOauth{})
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, user} = maybe_assoc_discord_oauth(user, user_params)

        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, discord_oauth: %DiscordOauth{})
    end
  end

  defp maybe_assoc_discord_oauth(user, %{"discord_oauth" => id}) do
    discord_oauth = Accounts.get_discord_oauth(id)
    Accounts.assoc_discord_oauth(user, discord_oauth)
  end

  defp maybe_assoc_discord_oauth(user, _params) do
    {:ok, user}
  end
end
