# @see https://www.rubydoc.info/docs/rails/ActiveModel/Type/Value
class Anchormodel::ActiveModelTypeValue < ActiveModel::Type::Value
  def initialize(attribute)
    @attribute = attribute
  end

  def cast(value)
    serialize value
  end

  # Implementing this instead of cast to force key validation in any case
  def serialize(value)
    return case value
    when Symbol, String
      unless @attribute.anchor_class.valid_keys.include?(value.to_sym)
        fail("Attempt to set #{@attribute.attribute_name} to unsupported key #{value.inspect}.")
      end
      value.to_s
    when @attribute.anchor_class
      value.key.to_s
    when nil
      nil
    else
      fail "Attempt to set #{@attribute.attribute_name} to unsupported type #{value.class}"
    end
  end

  def deserialize(value)
    return value if value.is_a?(@attribute.anchor_class)
    return @attribute.anchor_class.find(value)
  end

  def changed?(old_value, new_value, _new_value_before_type_cast)
    return deserialize(old_value) != deserialize(new_value)
  end
end
