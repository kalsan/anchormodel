# @api description
# Inherit from this class and place your Anchormodel under `app/anchormodels/your_anchor_model.rb`. Use it like `YourAnchorModel`.
# Refer to the README for usage.
class Anchormodel
  attr_reader :key
  attr_reader :index

  class_attribute :setup_completed, default: false
  class_attribute :entries_list, default: [] # For ordering
  class_attribute :entries_hash, default: {} # For quick access
  class_attribute :valid_keys, default: Set.new

  # When a descendant of Anchormodel is first used, it must overwrite the class_attributes
  # to prevent cross-class pollution.
  def self.setup!
    fail("`setup!` was called twice for Anchormodel subclass #{self}.") if setup_completed
    self.entries_list = entries_list.dup
    self.entries_hash = entries_hash.dup
    self.valid_keys = valid_keys.dup
    self.setup_completed = true
  end

  # Returns all possible values this Anchormodel can take.
  def self.all
    entries_list
  end

  # Retrieves a particular value given the key. Fails if not found.
  # @param key [String,Symbol] The key of the value that should be retrieved.
  def self.find(key)
    return nil if key.nil?
    return entries_hash[key.to_sym] || fail("Retreived undefined anchor model key #{key.inspect} for #{inspect}.")
  end

  # Call this initializer directly in your Anchormodel class. To set `@foo=:bar` for anchor `:ter`, use `new(:ter, foo: :bar)`
  # @param key [String,Symbol] The key under which the entry should be stored.
  # @param attributes All named arguments to Anchormodel are made available as instance attributes.
  def initialize(key, **attributes)
    self.class.setup! unless self.class.setup_completed

    @key = key.to_sym
    @index = entries_list.count

    # Save attributes as instance variables
    attributes.each do |k, v|
      instance_variable_set(:"@#{k}", v)
    end

    # Register self
    entries_list << self
    entries_hash[key] = self

    # Register valid keys
    valid_keys << key

    # Define boolean reader
    self.class.define_method(:"#{key}?") do
      @key == key
    end
  end

  def ==(other)
    self.class == other.class && key == other.key
  end

  # Returns a Rails label that is compatible with the [Rails FastGettext](https://github.com/grosser/gettext_i18n_rails/) gem.
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

require 'anchormodel/util'
require 'anchormodel/active_model_type_value_single'
require 'anchormodel/attribute'
require 'anchormodel/model_mixin'
require 'anchormodel/version'
require 'anchormodel/simple_form_inputs/helpers/anchormodel_inputs_common'
require 'anchormodel/simple_form_inputs/anchormodel_input'
require 'anchormodel/simple_form_inputs/anchormodel_radio_buttons_input'
