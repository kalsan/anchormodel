module Anchormodel::ModelMixin
  extend ActiveSupport::Concern

  included do
    class_attribute :anchormodel_attributes, default: {}.freeze
  end

  class_methods do
    def belongs_to_anchormodel(attribute_name, anchor_class_name=nil, optional: false)
      attribute_name = attribute_name.to_sym
      attribute = Anchormodel::Attribute.new(self, attribute_name, anchor_class_name, optional)

      # Register attribute
      self.anchormodel_attributes = anchormodel_attributes.merge({attribute_name => attribute}).freeze

      # Add presence validation if required
      unless optional
        validates attribute_name, presence: true
      end

      # Make casting work
      # Define serializer/deserializer
      active_model_type_value = Anchormodel::ActiveModelTypeValue.new(attribute)

      # Overwrite reader to force building anchors at every retrieval
      define_method(attribute_name.to_s) do
        active_model_type_value.deserialize(read_attribute(attribute_name))
      end

      # Override writer to fail early when an invalid target value is specified
      define_method("#{attribute_name}=") do |new_value|
        write_attribute(attribute_name, active_model_type_value.serialize(new_value))
      end

      # Supply serializer and deserializer
      attribute attribute_name, active_model_type_value
    end
  end
end