defmodule YourBotWeb.Components.BotModal do
  use Surface.Component

  alias SurfaceBulma.Button

  alias Surface.Components.{
    Form,
    Form.ErrorTag,
    Form.Field,
    Form.Label,
    Form.TextInput,
    Form.NumberInput,
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
          These values should be coppied from your bot's settings page
          See <a href="https://discord.com/developers/applications"> here </a> for more details
          <Form for={@changeset} submit="save" change="change" opts={autocomplete: "off"}>
            <Field name={:name}>
              <Label/>
              <div class="control">
                <TextInput opts={role: "fleet_name_input"}/>
              </div>
              <ErrorTag class="help is-danger"/>
            </Field>

            <Field name={:token}>
              <Label/>
              <div class="control">
              <TextInput opts={role: "fleet_name_input"}/>
              </div>
              <ErrorTag class="help is-danger"/>
            </Field>

            <Field name={:application_id}>
              <Label/>
              <div class="control">
              <NumberInput opts={role: "fleet_name_input"}/>
              </div>
              <ErrorTag class="help is-danger"/>
            </Field>

            <Field name={:public_key}>
              <Label/>
              <div class="control">
                <TextInput opts={role: "fleet_name_input"}/>
              </div>
              <ErrorTag class="help is-danger" />
            </Field>

            <Submit opts={disabled: !@changeset.valid?, role: "fleet_submit"} click={@hide_event}> Save </Submit>
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
