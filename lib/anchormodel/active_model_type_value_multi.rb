# ActiveModel type adapter for collection-valued anchormodel attributes (`belongs_to_anchormodels`).
#
# Translates between an in-memory `Set<Anchormodel>` and a CSV `String` stored in a single
# DB column. Inherits scalar handling from {Anchormodel::ActiveModelTypeValueSingle} and
# overrides the collection-aware methods.
#
# @see https://www.rubydoc.info/docs/rails/ActiveModel/Type/Value Rails type interface
class Anchormodel::ActiveModelTypeValueMulti < Anchormodel::ActiveModelTypeValueSingle
  # Splits the stored CSV and casts each entry into an Anchormodel instance.
  #
  # @param values [String,nil] CSV string from the DB, or `nil` (NULL).
  # @return [Set<Anchormodel>] Set of Anchormodel instances. Empty when `values` is nil or `""`.
  # @raise [Anchormodel::InvalidKey] if any CSV entry is not a registered key.
  def cast(values)
    return Set.new if values.nil?
    return values.split(',').map { |value| super(value) }.compact.to_set
  end

  # Serializes a Set/Array of anchormodel-shaped values into a CSV `String` for the DB.
  # Validates every entry and raises immediately on invalid keys (rather than deferring
  # the error to the next read).
  #
  # @param values [Enumerable,String,nil] Collection of anchormodel-shaped values, a
  #   pre-formed CSV `String`, or `nil`.
  # @return [String] CSV of validated keys, or `""` for nil / empty collection.
  # @raise [Anchormodel::InvalidKey] if any element is an unknown key.
  # @raise [RuntimeError] if `values` is not an Enumerable, String, or `nil`.
  def serialize(values)
    return case values
           when Enumerable
             values.map { |value| super(value) }.compact.join(',')
           when String
             values.split(',').map { |value| super(value) }.compact.join(',')
           when nil
             ''
           else
             fail "Attempt to set #{@attribute.attribute_name} to unsupported type #{values.class}"
           end
  end

  # Reports whether {#serialize} would accept `values`. Returns strict Boolean.
  #
  # @param values [Object]
  # @return [Boolean]
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
