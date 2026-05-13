unless defined? SimpleForm
  begin
    require 'simple_form'
  rescue LoadError
    nil
  end

end
if defined? SimpleForm
  # SimpleForm input for an anchormodel attribute. Renders a `<select>` collection
  # whose options are the entries of the bound anchormodel.
  #
  # Auto-detected by SimpleForm because the attribute's AR type is `:anchormodel`.
  #
  # @example
  #   <%= simple_form_for user do |f| %>
  #     <%= f.input :role %>
  #   <% end %>
  class AnchormodelInput < SimpleForm::Inputs::CollectionSelectInput
    include Anchormodel::SimpleFormInputs::Helpers::AnchormodelInputsCommon

    private

    def sf_selection_key
      :selected
    end

    def before_render_input; end
  end
end
