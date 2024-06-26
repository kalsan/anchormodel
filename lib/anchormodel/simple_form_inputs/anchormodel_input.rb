unless defined? SimpleForm
  begin
    require 'simple_form'
  rescue LoadError
    nil
  end

end
if defined? SimpleForm
  class AnchormodelInput < SimpleForm::Inputs::CollectionSelectInput
    include Anchormodel::SimpleFormInputs::Helpers::AnchormodelInputsCommon

    private

    def sf_selection_key
      :selected
    end

    def before_render_input; end
  end
end
