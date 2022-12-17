# @api description
# This class holds all information related to a Rails model pointing to an Anchormodel.
# It is instanciated when {Anchormodel::ModelMixin#belongs_to_anchormodel} is used.
class Anchormodel::Attribute
  attr_reader :attribute_name
  attr_reader :optional

  # @param model_class [ActiveRecord::Base] The Rails model where {Anchormodel::ModelMixin#belongs_to_anchormodel} is used
  # @param attribute_name [String,Symbol] The name and database column of the attribute
  # @param anchor_class_name [String] Name of the Anchormodel class (omit if attribute `:foo_bar` holds an `Anchormodels::FooBar`)
  # @param optional [Boolean] If true, a presence validation is added to the model.
  def initialize(model_class, attribute_name, anchor_class_name = nil, optional = false)
    @model_class = model_class
    @attribute_name = attribute_name.to_sym
    @anchor_class_name = anchor_class_name || "Anchormodels::#{attribute_name.to_s.classify}"
    @optional = optional
  end

  # Getter for the Anchormodel class based on the name passed to the initializer.
  # We are loading the anchor class lazily, because the model mixin instanciates this statically -> avoid premature anchor class loading
  def anchor_class
    @anchor_class ||= @anchor_class_name.constantize
  end
end
