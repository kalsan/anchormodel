class Anchormodel::ActiveModelTypeValueMulti < Anchormodel::ActiveModelTypeValueSingle
  # This converts DB or input to an Anchormodel instance
  def cast(values)
    return values.split(',').map { |value| super(value) }.compact.to_set
  end

  # This converts an Anchormodel instance to string for DB
  def serialize(values)
    return case values
           when Enumerable
             values.map { |value| super(value) }.compact.join(',')
           when String
             values
           when nil
             ''
           else
             fail "Attempt to set #{@attribute.attribute_name} to unsupported type #{values.class}"
           end
  end

  def serializable?(values)
    return case values
           when Enumerable
             values.map { |value| super(value) }.compact.join(',')
           when String
             values.split(',').map { |value| super(value) }.compact
           else
             false
           end
  end
end
