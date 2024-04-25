class Anchormodel
  module SimpleFormInputs
    module Helpers
      module AnchormodelInputsCommon
        def input(wrapper_options = nil)
          unless object.respond_to?(:anchormodel_attributes)
            fail("The form field object does not appear to respond to `anchormodel_attributes`, \
did you `include Anchormodel::ModelMixin` in your `application_record.rb`? Affected object: #{object.inspect}")
          end

          am_attr = object.anchormodel_attributes[@attribute_name]
          unless am_attr
            fail("#{@attribute_name.inspect} does not look like an Anchormodel attribute, is `belongs_to_anchormodel` called in your model? \
Affected object: #{object.inspect}")
          end
          am_class = am_attr.anchormodel_class
          options[:multiple] = true if am_attr.multiple? && options[:multiple] != false # allow overriding

          # Attempt to read selected key from html input options "value", as the caller might not know that this is a select.
          selected_key = input_options[:value]
          if selected_key.blank? && object
            # No selected key override present and a model is present, use the model to find out what to select.
            selected_am = object.send(@attribute_name)
            if am_attr.multiple?
              selected_key = selected_am&.map(&:key)&.map(&:to_s) || []
            else
              selected_key = (selected_am&.key || am_class.all.first).to_s
            end
          end

          options.deep_merge!(
            label_method:  :first,
            value_method:  :second,
            sf_selection_key =>       selected_key,
            include_blank: !am_attr.multiple? && am_attr.optional
          )

          @collection = collect(am_class.all)

          before_render_input

          super
        end

        private

        # Takes an array of objects implementing the methods `label` and `key` and returns an array suitable for simple_form select fields.
        def collect(flat_array)
          return flat_array.map { |entry| [entry.label, entry.key] }
        end
      end
    end
  end
end
