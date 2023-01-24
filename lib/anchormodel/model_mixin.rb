# @api description
# All Rails models making use of #belongs_to_anchormodel must include this mixin. Typically, it is included in `application_record.rb`.
module Anchormodel::ModelMixin
  extend ActiveSupport::Concern

  included do
    class_attribute :anchormodel_attributes, default: {}.freeze
  end

  class_methods do
    # Creates an attribute linking to an Anchormodel. The attribute should be
    # present in the DB and the column should be named the same as `attribute_name.`
    # @param attribute_name [String,Symbol] The name and database column of the attribute
    # @param anchormodel_class [Class] Class of the Anchormodel (omit if attribute `:foo_bar` holds a `FooBar`)
    # @param optional [Boolean] If true, a presence validation is added to the model.
    # @param model_readers [Boolean] If true, the model is given an ActiveRecord::Enum style method `my_model.my_key?` reader for each key in the anchormodel
    # @param model_writers [Boolean] If true, the model is given an ActiveRecord::Enum style method `my_model.my_key!` writer for each key in the anchormodel
    # @param model_scopes [Boolean] If true, the model is given an ActiveRecord::Enum style scope `MyModel.mykey` for each key in the anchormodel
    # @param model_methods [Boolean, NilClass] If non-nil, this mass-assigns and overrides `model_readers`, `model_writers` and `model_scopes`
    def belongs_to_anchormodel(attribute_name, anchormodel_class = nil, optional: false, model_readers: true,
                                model_writers: true, model_scopes: true, model_methods: nil)
      anchormodel_class ||= attribute_name.to_s.classify.constantize
      attribute_name = attribute_name.to_sym
      attribute = Anchormodel::Attribute.new(self, attribute_name, anchormodel_class, optional)

      # Mass configurations if model_methods was specfied
      unless model_methods.nil?
        model_readers = model_methods
        model_writers = model_methods
        model_scopes = model_methods
      end

      # Register attribute
      self.anchormodel_attributes = anchormodel_attributes.merge({ attribute_name => attribute }).freeze

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

      # Create ActiveRecord::Enum style reader directly in the model if asked to do so
      # For a model User with anchormodel Role with keys :admin and :guest, this creates user.admin? and user.guest? (returning true iff role is admin/guest)
      if model_readers
        anchormodel_class.all.each do |entry|
          if respond_to?(:"#{entry.key}?")
            fail("Anchormodel reader #{entry.key}? already defined for #{self}, add `model_readers: false` to `belongs_to_anchormodel :#{attribute_name}`.")
          end
          define_method(:"#{entry.key}?") do
            public_send(attribute_name.to_s) == entry
          end
        end
      end

      # Create ActiveRecord::Enum style writer directly in the model if asked to do so
      # For a model User with anchormodel Role with keys :admin and :guest, this creates user.admin! and user.guest! (setting the role to admin/guest)
      if model_writers
        anchormodel_class.all.each do |entry|
          if respond_to?(:"#{entry.key}!")
            fail("Anchormodel writer #{entry.key}! already defined for #{self}, add `model_writers: false` to `belongs_to_anchormodel :#{attribute_name}`.")
          end
          define_method(:"#{entry.key}!") do
            public_send(:"#{attribute_name.to_s}=", entry)
          end
        end
      end

      # Create ActiveRecord::Enum style scope directly in the model class if asked to do so
      # For a model User with anchormodel Role with keys :admin and :guest, this creates user.admin! and user.guest! (setting the role to admin/guest)
      if model_scopes
        anchormodel_class.all.each do |entry|
          if respond_to?(entry.key)
            fail("Anchormodel scope #{entry.key} already defined for #{self}, add `model_scopes: false` to `belongs_to_anchormodel :#{attribute_name}`.")
          end
          scope(entry.key, ->{where(attribute_name => entry.key)})
        end
      end
    end
  end
end
