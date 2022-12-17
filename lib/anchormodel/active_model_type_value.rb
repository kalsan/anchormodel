class Anchormodel::ActiveModelTypeValue < ActiveModel::Type::Value
  def initialize(attribute)
    @attribute = attribute
  end

  def cast(value)
    return case value
    when Symbol, String
      unless @anchor_association.anchor_class.valid_keys.include?(value.to_sym)
        fail("Attempt to set #{@anchor_association.attribute_name} to unsupported key #{value.inspect}.")
      end
      value.to_s
    when @anchor_association.anchor_class
      value.key.to_s
    when nil
      nil
    else
      fail "Attempt to set #{@anchor_association.attribute_name} to unsupported type #{value.class}"
    end
  end
end
