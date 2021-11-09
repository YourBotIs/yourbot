defmodule MonacoEditor do
  use Surface.LiveComponent

  def render(assigns) do
    ~F"""
    <div :hook="MonacoEditor"
          id="container"
          style="padding-right: 1.5rem; width: 800px; height: 600px;"
          role="monaco_editor"
    />
    """
  end
end
