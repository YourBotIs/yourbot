defmodule YourBotWeb.Router do
  use YourBotWeb, :router
  import Surface.Catalogue.Router
  import YourBotWeb.UserAuth
  use PhoenixSwagger

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {YourBotWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug SocketDrano.Plug
  end

  pipeline :api do
    plug :accepts, ["json", "html"]
    plug SocketDrano.Plug
  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :yourbot, swagger_file: "swagger.json"
  end

  scope "/api", YourBotWeb do
    pipe_through [:api, :require_authenticated_api_token]
    resources "/users", UsersController, only: [:create, :show, :update, :delete]
    post "/users/:id/token", UsersController, :token
    get "/users/:id/bots", BotsController, :show_bots_for_user

    resources "/bots", BotsController, only: [:index, :create, :show, :update, :delete] do
      post "/code", BotsController, :code

      resources "/environment_variables", EnvironmentVariableController,
        only: [:index, :create, :show, :update, :delete]
    end
  end

  scope "/", YourBotWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/tos", PageController, :tos
    get "/privacy-policy", PageController, :privacy_policy
    live "/demo", Demo
  end

  # Other scopes may use custom stacks.
  # scope "/api", YourBotWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: YourBotWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", YourBotWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]
  end

  scope "/", YourBotWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/bots", BotLive, :index
  end

  scope "/", YourBotWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
    get "/oauth/discord", DiscordOAuthController, :oauth
  end

  if Mix.env() == :dev do
    scope "/" do
      pipe_through :browser
      surface_catalogue("/catalogue")
    end
  end

  def swagger_info do
    %{
      securityDefinitions: %{
        Bearer: %{
          type: "apiKey",
          name: "Authorization",
          description: "API Token must be provided via `Authorization: Bearer ` header",
          in: "header"
        }
      },
      consumes: ["application/json"],
      produces: ["application/json"],
      basePath: "/api",
      info: %{
        version: "1.0",
        title: "YourBot API"
      },
      tags: [
        %{name: "Users", description: "Operations about Users"},
        %{name: "Bots", description: "Operations about Bots"},
        %{name: "EnvironmentVariables", description: "Operations about env vars"}
      ]
    }
  end
end
