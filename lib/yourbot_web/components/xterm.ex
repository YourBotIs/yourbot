defmodule XTerm do
  use Surface.LiveComponent

  def render(assigns) do
    ~F"""
    <div :hook="XtermHook" id="XTerm"/>
    """
  end
end
