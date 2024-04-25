# @api description
# A swiss army knife for common functionality
module Anchormodel::Util
  # Installs an anchormodel attribute in a model class
  # @param model_class [ActiveRecord::Base] Internal only. The model class that the attribute should be installed to.
  # @param attribute_name [String,Symbol] The name and database column of the attribute
  # @param anchormodel_class [Class] Class of the Anchormodel (omit if attribute `:foo_bar` holds a `FooBar`)
  # @param optional [Boolean] If false, a presence validation is added to the model. Forced to true if multiple is true.
  # @param multiple [Boolean] Internal only. Distinguishes between `belongs_to_anchormodel` and `belongs_to_anchormodels`.
  # @param model_readers [Boolean] If true, the model is given an ActiveRecord::Enum style method `my_model.my_key?` reader for each key in the anchormodel
  # @param model_writers [Boolean] If true, the model is given an ActiveRecord::Enum style method `my_model.my_key!` writer for each key in the anchormodel
  # @param model_scopes [Boolean] If true, the model is given an ActiveRecord::Enum style scope `MyModel.mykey` for each key in the anchormodel
  # @param model_methods [Boolean, NilClass] If non-nil, this mass-assigns and overrides `model_readers`, `model_writers` and `model_scopes`
  def self.install_methods_in_model(model_class, attribute_name, anchormodel_class = nil,
                                    optional: false,
                                    multiple: false,
                                    model_readers: true,
                                    model_writers: true,
                                    model_scopes: true,
                                    model_methods: nil)

    optional = true if multiple
    anchormodel_class ||= attribute_name.to_s.classify.constantize
    attribute_name = attribute_name.to_sym
    attribute = Anchormodel::Attribute.new(model_class, attribute_name, anchormodel_class, optional, multiple)

    # Mass configurations if model_methods was specfied
    unless model_methods.nil?
      model_readers = model_methods
      model_writers = model_methods
      model_scopes = model_methods
    end

    # Register attribute
    model_class.anchormodel_attributes = model_class.anchormodel_attributes.merge({ attribute_name => attribute }).freeze

    # Add presence validation if required
    unless optional
      model_class.validates attribute_name, presence: true
    end

    # Make casting work
    # Define serializer/deserializer
    active_model_type_value = (multiple ? Anchormodel::ActiveModelTypeValueMulti : Anchormodel::ActiveModelTypeValueSingle).new(attribute)

    # Overwrite reader to force building anchors at every retrieval
    model_class.define_method(attribute_name.to_s) do
      result = active_model_type_value.deserialize(read_attribute_before_type_cast(attribute_name))

      # If this attribute holds multiple anchormodels (`belongs_to_anchormodels`), patch the Array before returning in order to implement collection modifiers:
      if multiple
        model = self # fetching the model in order to pass it to the implementation of the following via reflection to make it available for storage
        single_tv = Anchormodel::ActiveModelTypeValueSingle.new(attribute) # Used for casting inputs to properly compare them to the set.

        # Adding
        result.define_singleton_method('add') do |value_to_add|
          super(single_tv.cast(value_to_add))
          model.write_attribute(attribute_name, active_model_type_value.serialize(self))
          next self
        end
        result.define_singleton_method('<<') { |value_to_add| add(single_tv.cast(value_to_add)) }

        # Deleting
        result.define_singleton_method('delete') do |value_to_delete|
          super(single_tv.cast(value_to_delete))
          model.write_attribute(attribute_name, active_model_type_value.serialize(self))
          next self
        end

        # Clearing
        result.define_singleton_method('clear') do
          super()
          model.write_attribute(attribute_name, active_model_type_value.serialize(self))
          next self
        end

        # In the future, further methods could be supported. e.g. delete_if, subtract etc.
      end

      return result
    end

    # Override writer to fail early when an invalid target value is specified
    model_class.define_method("#{attribute_name}=") do |new_value|
      write_attribute(attribute_name, active_model_type_value.serialize(new_value))
    end

    # Supply serializer and deserializer
    model_class.attribute attribute_name, active_model_type_value

    # Create ActiveRecord::Enum style reader directly in the model if asked to do so
    # For a model User with anchormodel Role with keys :admin and :guest, this creates user.admin? and user.guest? (returning true iff role is admin/guest)
    if model_readers
      anchormodel_class.all.each do |entry|
        if model_class.respond_to?(:"#{entry.key}?")
          fail("Anchormodel reader #{entry.key}? already defined for #{self}, add `model_readers: false` to `belongs_to_anchormodel :#{attribute_name}`.")
        end
        model_class.define_method(:"#{entry.key}?") do
          if multiple
            public_send(attribute_name.to_s).include?(entry)
          else
            public_send(attribute_name.to_s) == entry
          end
        end
      end
    end

    # Create ActiveRecord::Enum style writer directly in the model if asked to do so
    # For a model User with anchormodel Role with keys :admin and :guest, this creates user.admin! and user.guest! (setting the role to admin/guest)
    if model_writers
      anchormodel_class.all.each do |entry|
        if model_class.respond_to?(:"#{entry.key}!")
          fail("Anchormodel writer #{entry.key}! already defined for #{self}, add `model_writers: false` to `belongs_to_anchormodel :#{attribute_name}`.")
        end
        model_class.define_method(:"#{entry.key}!") do
          if multiple
            public_send(attribute_name.to_s) << entry
          else
            public_send(:"#{attribute_name}=", entry)
          end
        end
      end
    end

    # Create ActiveRecord::Enum style scope directly in the model class if asked to do so
    # For a model User with anchormodel Role with keys :admin and :guest, this creates user.admin! and user.guest! (setting the role to admin/guest)
    if model_scopes
      anchormodel_class.all.each do |entry|
        if model_class.respond_to?(entry.key)
          fail("Anchormodel scope #{entry.key} already defined for #{self}, add `model_scopes: false` to `belongs_to_anchormodel :#{attribute_name}`.")
        end
        if multiple
          model_class.scope(entry.key, lambda {
                                         where("#{attribute_name} LIKE ? OR #{attribute_name} LIKE ? OR #{attribute_name} LIKE ? OR #{attribute_name} LIKE ?",
                                               "%#{entry.key},%", "%#{entry.key}", "#{entry.key},%", entry.key.to_s)
                                       })
        else
          model_class.scope(entry.key, -> { where(attribute_name => entry.key) })
        end
      end
    end
  end
end
