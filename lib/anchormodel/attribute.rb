# Metadata about an anchormodel attribute installed on a Rails model.
#
# One instance is created per call to {Anchormodel::ModelMixin#belongs_to_anchormodel}
# or {Anchormodel::ModelMixin#belongs_to_anchormodels} and stored in the model class's
# `anchormodel_attributes` hash. Used internally by the AR type casters and by SimpleForm
# inputs to discover what an attribute points to.
class Anchormodel::Attribute
  # @!attribute [r] attribute_name
  #   @return [Symbol] The model attribute / DB column name.
  attr_reader :attribute_name

  # @!attribute [r] anchormodel_class
  #   @return [Class] The Anchormodel subclass this attribute references.
  attr_reader :anchormodel_class

  # @!attribute [r] optional
  #   @return [Boolean] Whether the attribute may be `nil` (no presence validation added).
  attr_reader :optional

  # @param model_class [Class] The ActiveRecord model class on which {Anchormodel::ModelMixin#belongs_to_anchormodel} is called.
  # @param attribute_name [String,Symbol] The model attribute / DB column name.
  # @param anchormodel_class [Class,nil] The Anchormodel subclass. Omit if attribute `:foo_bar` references `FooBar`.
  # @param optional [Boolean] If true, no presence validation is added.
  # @param multiple [Boolean] If true, this attribute holds a Set of anchormodels (CSV in column).
  def initialize(model_class, attribute_name, anchormodel_class = nil, optional = false, multiple = false)
    @model_class = model_class
    @attribute_name = attribute_name.to_sym
    @anchormodel_class = anchormodel_class
    @optional = optional
    @multiple = multiple
  end

  # @return [Boolean] true for `belongs_to_anchormodels` (collection), false for `belongs_to_anchormodel` (single).
  def multiple?
    @multiple
  end
end
