defmodule YourBotWeb.Demo do
  use Surface.LiveView

  alias YourBotWeb.Components.Hero
  alias MonacoEditor

  def render(assigns) do
    ~F"""
    <div>
      <Hero name="John Doe" subtitle="How are you?" color="info"/>
      <MonacoEditor id="editor" />
    </div>
    """
  end
end
