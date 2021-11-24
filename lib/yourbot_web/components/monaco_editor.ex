defmodule MonacoEditor do
  use Surface.LiveComponent

  def render(assigns) do
    ~F"""
    <div class="rb">
      <div class="myME">
        <div :hook="MonacoEditor"
              id="container"
              role="monaco_editor"
              class="buffer">
        </div>
      </div>
    </div>
    """
  end
end
