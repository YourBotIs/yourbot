defmodule YourBot.Accounts.APIToken do
  @secret Application.get_env(:yourbot, __MODULE__)[:secret]
  use Ecto.Schema

  schema "api_tokens" do
    belongs_to :user, YourBot.Accounts.User
    field :token, :string, null: false
  end

  def jwk do
    %{
      "kty" => "oct",
      "k" => :jose_base64url.encode(@secret)
    }
  end

  def jws do
    %{
      "alg" => "HS256"
    }
  end

  def generate(user) do
    iss = YourBotWeb.Endpoint.url()
    nonce = :crypto.strong_rand_bytes(64) |> Base.encode16()
    exp = DateTime.utc_now() |> DateTime.to_unix()

    jwt = %{
      "iss" => iss,
      "exp" => exp,
      "nonce" => nonce,
      "user_id" => user.id
    }

    {_, token} =
      JOSE.JWT.sign(jwk(), jws(), jwt)
      |> JOSE.JWS.compact()

    YourBot.Repo.insert!(%__MODULE__{token: token, user_id: user.id})
  end

  def verify(signed) do
    with {true, %{fields: %{"user_id" => user_id}}, _} <- JOSE.JWT.verify(jwk(), signed),
         %__MODULE__{} <- YourBot.Repo.get_by(__MODULE__, token: signed, user_id: user_id) do
      {:ok, YourBot.Repo.get!(YourBot.Accounts.User, user_id)}
    else
      _ -> :error
    end
  end
end
