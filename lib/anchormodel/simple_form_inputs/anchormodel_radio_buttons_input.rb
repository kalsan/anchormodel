unless defined? SimpleForm
  begin
    require 'simple_form'
  rescue LoadError
    nil
  end

end
if defined? SimpleForm
  # SimpleForm input for a single-value anchormodel attribute, rendered as radio buttons.
  # Unsuitable for collection attributes — use {AnchormodelCheckBoxesInput} for those.
  #
  # @example
  #   <%= simple_form_for user do |f| %>
  #     <%= f.input :role, as: :anchormodel_radio_buttons %>
  #   <% end %>
  class AnchormodelRadioButtonsInput < SimpleForm::Inputs::CollectionRadioButtonsInput
    include Anchormodel::SimpleFormInputs::Helpers::AnchormodelInputsCommon

    private

    def sf_selection_key
      :checked
    end

    def before_render_input
      @input_type = :radio_buttons
    end
  end
end
