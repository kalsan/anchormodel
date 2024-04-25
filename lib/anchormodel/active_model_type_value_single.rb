# @see https://www.rubydoc.info/docs/rails/ActiveModel/Type/Value
class Anchormodel::ActiveModelTypeValueSingle < ActiveModel::Type::Value
  attr_reader :attribute

  def initialize(attribute)
    super()
    @attribute = attribute
  end

  def type
    :anchormodel
  end

  # This converts DB or input to an Anchormodel instance
  def cast(value)
    value = value.presence
    return value if value.is_a?(@attribute.anchormodel_class)
    return @attribute.anchormodel_class.find(value)
  end

  # This converts an Anchormodel instance to string for DB
  def serialize(value)
    value = value.presence
    return case value
           when Symbol, String
             unless @attribute.anchormodel_class.valid_keys.include?(value.to_sym)
               fail("Attempt to set #{@attribute.attribute_name} to unsupported key #{value.inspect}.")
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

  def serializable?(value)
    return case value
           when Symbol, String
             @attribute.anchormodel_class.valid_keys.exclude?(value.to_sym)
           when nil, @attribute.anchormodel_class
             true
           else
             false
           end
  end

  def changed_in_place?(raw_old_value, value)
    old_value = deserialize(raw_old_value)
    old_value != value
  end
end
