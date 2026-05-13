# ActiveModel type adapter for single-value anchormodel attributes.
#
# Translates between the in-memory Ruby form (an `Anchormodel` instance or `nil`) and
# the on-disk form (a String key in the DB column). Registered with AR via
# `model_class.attribute(name, ActiveModelTypeValueSingle.new(attribute))` by
# {Anchormodel::Util.install_methods_in_model}.
#
# @see https://www.rubydoc.info/docs/rails/ActiveModel/Type/Value Rails type interface
class Anchormodel::ActiveModelTypeValueSingle < ActiveModel::Type::Value
  # @!attribute [r] attribute
  #   @return [Anchormodel::Attribute] Metadata about the column this type is bound to.
  attr_reader :attribute

  # @param attribute [Anchormodel::Attribute]
  def initialize(attribute)
    super()
    @attribute = attribute
  end

  # @return [Symbol] `:anchormodel` — the type identifier.
  def type
    :anchormodel
  end

  # Coerces an input value into an Anchormodel instance (or nil). Used by Rails when
  # reading from the DB, when assigning via mass-assignment, and for dirty-tracking.
  #
  # @param value [String,Symbol,Anchormodel,nil] DB value, user input, or already-cast instance.
  # @return [Anchormodel,nil] The matching Anchormodel instance, or `nil` for blank input.
  # @raise [Anchormodel::InvalidKey] if a String/Symbol is not a registered key.
  def cast(value)
    value = value.presence
    return value if value.is_a?(@attribute.anchormodel_class)
    return @attribute.anchormodel_class.find(value)
  end

  # Converts an Anchormodel-shaped value into the String key stored in the DB.
  #
  # @param value [String,Symbol,Anchormodel,nil]
  # @return [String,nil] The key as a String, or `nil` for blank input.
  # @raise [Anchormodel::InvalidKey] for unknown String/Symbol keys.
  # @raise [RuntimeError] for any other input type (e.g. Array, Integer).
  def serialize(value)
    serialize_scalar(value)
  end

  # Reports whether `value` is a shape that {#serialize} would accept. Used by AR's
  # `Arel::Nodes::HomogeneousIn` to gate which array elements get bound into IN clauses.
  # Returns true for any String/Symbol/`nil`/Anchormodel instance — actual key validation
  # is deferred to {#serialize}.
  #
  # @param value [Object]
  # @return [Boolean]
  def serializable?(value)
    scalar_serializable?(value)
  end

  # Used by AR's dirty tracking to detect in-place mutation.
  # @api private
  def changed_in_place?(raw_old_value, value)
    old_value = deserialize(raw_old_value)
    old_value != value
  end

  private

  def serialize_scalar(value)
    value = value.presence
    return case value
           when Symbol, String
             unless @attribute.anchormodel_class.valid_keys.include?(value.to_sym)
               raise(Anchormodel::InvalidKey, "Attempt to set #{@attribute.attribute_name} to unsupported key #{value.inspect}.")
             end
             value.to_s
           when @attribute.anchormodel_class
             value.key.to_s
           when nil
             nil
           else
             fail "Attempt to set #{@attribute.attribute_name} to unsupported type #{value.class}"
           end
  end

  def scalar_serializable?(value)
    return case value
           when Symbol, String, nil, @attribute.anchormodel_class
             true
           else
             false
           end
  end
end
