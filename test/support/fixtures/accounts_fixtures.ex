defmodule YourBot.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `YourBot.Accounts` context.
  """
  import YourBot.UniqueData

  def unique_user_email, do: unique_email("user")
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    attrs = valid_user_attributes(attrs)
    {:ok, user} = YourBot.Accounts.register_user(attrs)
    %{user | password: attrs[:password]}
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
end
