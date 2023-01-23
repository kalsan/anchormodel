# @api description
# This class holds all information related to a Rails model pointing to an Anchormodel.
# It is instanciated when {Anchormodel::ModelMixin#belongs_to_anchormodel} is used.
class Anchormodel::Attribute
  attr_reader :attribute_name
  attr_reader :anchormodel_class
  attr_reader :optional

  # @param model_class [ActiveRecord::Base] The Rails model where {Anchormodel::ModelMixin#belongs_to_anchormodel} is used
  # @param attribute_name [String,Symbol] The name and database column of the attribute
  # @param anchormodel_class [Class] Class of the Anchormodel (omit if attribute `:foo_bar` holds an `FooBar`)
  # @param optional [Boolean] If true, a presence validation is added to the model.
  def initialize(model_class, attribute_name, anchormodel_class = nil, optional = false)
    @model_class = model_class
    @attribute_name = attribute_name.to_sym
    @anchormodel_class = anchormodel_class
    @optional = optional
  end
end
