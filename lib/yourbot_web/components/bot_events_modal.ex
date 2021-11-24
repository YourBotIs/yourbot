defmodule YourBotWeb.Components.BotEventsModal do
  use Surface.Component

  alias SurfaceBulma.Button

  prop title, :string, required: true
  prop show, :boolean, required: true
  prop hide_event, :event, required: true
  prop events, :list, required: true

  def render(assigns) do
    ~F"""
    <div class={"modal", "is-active": @show}>
      <div class="modal-background" />
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">{@title}</p>
        </header>
        <section class="modal-card-body">
          <table class="table">
          <thead>
            <tr>
              <th>Event</th>
              <th>Content</th>
              <th>Inserted</th>
            </tr>
          </thead>
          <tfoot>
            <tr>
              <th>Event</th>
              <th>Content</th>
              <th>Inserted</th>
            </tr>
          </tfoot>
          <tbody>
            {#for event <- @events}
              <tr>
                <td> {event.name} </td>
                <td> {event.content} </td>
                <td> {event.inserted_at} </td>
              </tr>
            {/for}
          </tbody>
        </table>
        </section>
        <footer class="modal-card-foot" style="justify-content: flex-end">
          <Button click={@hide_event}>Close</Button>
        </footer>
      </div>
    </div>
    """
  end
end
