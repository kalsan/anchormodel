class Anchormodel
  attr_reader :key
  attr_reader :index
  class_attribute :entries_list, default: [] # For ordering
  class_attribute :entries_hash, default: {} # For quick access

  # To set @foo=:bar for anchor :ter, use new(:ter, foo: :bar)
  def initialize(key, **attributes)
    @key = key.to_sym
    @index = self.entries_list.count

    # Save attributes as instance variables
    attributes.each do |k, v|
      instance_variable_set(:"@#{k}", v)
    end

    # Register self
    entries_list << self
    entries_hash[key] = self
  end
end

require 'anchormodel/version'
