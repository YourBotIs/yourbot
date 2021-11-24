defmodule YourBotWeb.Components.EnvVarModal do
  use Surface.Component

  alias SurfaceBulma.Button

  alias Surface.Components.{
    Form,
    Form.ErrorTag,
    Form.Field,
    Form.Label,
    Form.TextInput,
    Form.Submit
  }

  prop title, :string, required: true
  prop show, :boolean, required: true
  prop hide_event, :event, required: true
  prop changeset, :map, required: true

  def render(assigns) do
    ~F"""
    <div class={"modal", "is-active": @show}>
      <div class="modal-background" />
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">{@title}</p>
        </header>
        <section class="modal-card-body">
          Environment variables are a way to store secrets in your code safely
          <Form for={@changeset} submit="save" change="change" opts={autocomplete: "off"}>
            <Field name={:key}>
              <Label/>
              <div class="control">
                <TextInput opts={role: "var_name_input"}/>
              </div>
              <ErrorTag class="help is-danger"/>
            </Field>

            <Field name={:value}>
              <Label/>
              <div class="control">
              <TextInput opts={role: "var_value_input"}/>
              </div>
              <ErrorTag class="help is-danger"/>
            </Field>
            <Submit opts={disabled: !@changeset.valid?, role: "bot_submit"} click={@hide_event}> Save </Submit>
          </Form>
        </section>
        <footer class="modal-card-foot" style="justify-content: flex-end">
          <Button click={@hide_event}>Close</Button>
        </footer>
      </div>
    </div>
    """
  end
end
