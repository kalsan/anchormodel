unless defined? SimpleForm
  begin
    require 'simple_form'
  rescue LoadError
    nil
  end

end
if defined? SimpleForm
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
