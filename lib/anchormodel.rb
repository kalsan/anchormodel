class Anchormodel
  attr_reader :key
  attr_reader :index
  class_attribute :entries_list, default: [] # For ordering
  class_attribute :entries_hash, default: {} # For quick access
  class_attribute :valid_keys, default: Set.new

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

    # Register valid keys
    valid_keys << key
  end

  def ==(other)
    self.class == other.class && key == other.key
  end

  def label
    I18n.t("#{self.class.name.demodulize}|#{key.to_s.humanize}")
  end

  def inspect
    "#<#{self.class.name}<#{key}>:#{hash}>"
  end

  def to_s
    inspect
  end
end

require 'anchormodel/attribute'
require 'anchormodel/version'
