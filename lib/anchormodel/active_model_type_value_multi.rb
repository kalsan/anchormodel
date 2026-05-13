class Anchormodel::ActiveModelTypeValueMulti < Anchormodel::ActiveModelTypeValueSingle
  # This converts DB or input to an Anchormodel instance
  def cast(values)
    return Set.new if values.nil?
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
             values.all? { |value| super(value) }
           when String
             values.split(',').all? { |value| super(value) }
           when nil
             true
           else
             false
           end
  end
end
