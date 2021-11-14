defmodule YourBot.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `YourBot.Accounts` context.
  """
  import YourBot.UniqueData

  def unique_user_email, do: unique_email("user")

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  def valid_discord_oauth_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      discord_user_id: unique_id(),
      avatar: unique_name("discord avatar"),
      username: unique_name("discord_username"),
      discriminator: unique_name("discor discrim")
    })
  end

  def user_fixture(attrs \\ %{}) do
    attrs = valid_user_attributes(attrs)
    {:ok, user} = YourBot.Accounts.register_user(attrs)
    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def setup_user(env) do
    user = user_fixture()
    Map.put(env, :user, user)
  end

  def setup_discord_oauth(env) do
    {:ok, discord_oauth} = YourBot.Accounts.create_discord_oauth(valid_discord_oauth_attributes())
    {:ok, user} = YourBot.Accounts.assoc_discord_oauth(env.user, discord_oauth)
    Map.put(%{env | user: user}, :discord_oauth, discord_oauth)
  end

  def setup_api_token(env) do
    %{token: token} = YourBot.Accounts.APIToken.generate(env.user)
    conn = Plug.Conn.put_req_header(env.conn, "bearer", token)
    %{env | conn: conn}
  end
end
