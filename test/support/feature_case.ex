defmodule YourBotWeb.FeatureCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      require Logger

      use Wallaby.Feature
      import Wallaby.Query

      alias YourBotWeb.Router.Helpers, as: Routes
      import YourBot.UniqueData

      if System.get_env("SHOW_BROWSER") do
        setup :show_browser
      end

      @endpoint YourBotWeb.Endpoint
      @moduletag :wallaby

      def show_browser(env) do
        Logger.warning("Running chromium in headed mode.")

        {:ok, session} =
          Wallaby.start_session(
            capabilities: %{
              javascriptEnabled: true
            }
          )

        Map.put(env, :session, session)
      end
    end
  end
end
