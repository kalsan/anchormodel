unless defined? SimpleForm
  begin
    require 'simple_form'
  rescue LoadError
    nil
  end

end
if defined? SimpleForm
  # SimpleForm input for a collection-valued anchormodel attribute (`belongs_to_anchormodels`),
  # rendered as check boxes (one per anchormodel key).
  #
  # @example
  #   <%= simple_form_for user do |f| %>
  #     <%= f.input :animals, as: :anchormodel_check_boxes %>
  #   <% end %>
  class AnchormodelCheckBoxesInput < SimpleForm::Inputs::CollectionCheckBoxesInput
    include Anchormodel::SimpleFormInputs::Helpers::AnchormodelInputsCommon

    private

    def sf_selection_key
      :checked
    end

    def before_render_input
      @input_type = :check_boxes
    end
  end
end
