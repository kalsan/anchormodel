# An Anchormodel is a registry of named constants that behave like first-class objects.
# It is a richer alternative to Rails Enums: each entry is a real Ruby instance that can
# carry behavior and per-key attributes while still being persistable to a String column
# in the database.
#
# Place anchormodel subclasses under `app/anchormodels/your_anchor_model.rb` so Rails
# autoloading picks them up. Refer to the README for usage.
#
# @example Define an anchormodel
#   class Role < Anchormodel
#     include Comparable
#     attr_reader :privilege_level
#
#     def <=>(other) = privilege_level <=> other.privilege_level
#
#     new :guest,   privilege_level: 0
#     new :manager, privilege_level: 1
#     new :admin,   privilege_level: 2
#   end
#
# @example Use it from an ActiveRecord model
#   class User < ApplicationRecord
#     belongs_to_anchormodel :role
#   end
#
#   user = User.create!(role: :admin)
#   user.role                   # => #<Role<admin>:...>
#   user.role.privilege_level   # => 2
#   user.admin?                 # => true
class Anchormodel
  # @!attribute [r] key
  #   @return [Symbol] The key under which this entry was registered.
  attr_reader :key

  # @!attribute [r] index
  #   @return [Integer] Zero-based declaration order within the subclass.
  attr_reader :index

  class_attribute :setup_completed, default: false
  class_attribute :entries_list, default: [] # For ordering
  class_attribute :entries_hash, default: {} # For quick access
  class_attribute :valid_keys, default: Set.new

  # Initializes the per-subclass registry on first use. Called automatically from
  # the first `new` invocation. Each subclass gets its own duped copies of the
  # registry class attributes to prevent cross-class pollution.
  #
  # You normally do not need to call this directly.
  #
  # @return [void]
  # @raise [RuntimeError] if called twice for the same subclass.
  def self.setup!
    fail("`setup!` was called twice for Anchormodel subclass #{self}.") if setup_completed
    self.entries_list = entries_list.dup
    self.entries_hash = entries_hash.dup
    self.valid_keys = valid_keys.dup
    self.setup_completed = true
  end

  # @return [Array<Anchormodel>] All registered entries of this subclass, in declaration order.
  # @example
  #   Role.all # => [#<Role<guest>>, #<Role<manager>>, #<Role<admin>>]
  def self.all
    entries_list
  end

  # Shorthand for `all.first`. Provided so callers can avoid Rubocop's
  # `Style/FirstElementInCollection`-style warnings on `Foo.all.first`.
  # @return [Anchormodel,nil] The first registered entry, or `nil` if the registry is empty.
  def self.first
    all.first
  end

  # Builds a `[label, key_string]` tuple list suitable for Rails form select helpers.
  # @return [Array<Array(String,String)>]
  # @example
  #   <%= form.select :role, Role.form_collection %>
  def self.form_collection
    entries_list.map { |el| [el.label, el.key.to_s] }
  end

  # Raised when an anchormodel key is unknown to its class — i.e. no `new :that_key`
  # call was made on the subclass.
  #
  # Inherits from `RuntimeError` so existing `rescue RuntimeError` blocks remain
  # compatible while allowing the narrower `rescue Anchormodel::InvalidKey`.
  class InvalidKey < RuntimeError; end

  # Retrieves the entry registered under `key`.
  #
  # @param key [String,Symbol,nil] The key of the value that should be retrieved.
  # @return [Anchormodel,nil] The matching entry, or `nil` if `key` is `nil`.
  # @raise [Anchormodel::InvalidKey] if no entry with that key exists.
  # @example
  #   Role.find(:admin)   # => #<Role<admin>>
  #   Role.find('admin')  # => #<Role<admin>>   (same singleton instance)
  #   Role.find(nil)      # => nil
  #   Role.find(:nope)    # raises Anchormodel::InvalidKey
  def self.find(key)
    return nil if key.nil?
    return entries_hash[key.to_sym] || raise(InvalidKey, "Retrieved undefined anchor model key #{key.inspect} for #{inspect}.")
  end

  # Registers a new entry. Called in the body of an Anchormodel subclass.
  # All keyword arguments become instance attributes accessible via `attr_reader`.
  #
  # @param key [String,Symbol] The unique key under which the entry is registered.
  # @param attributes [Hash] Arbitrary attributes exposed as instance variables.
  # @raise [RuntimeError] if `key` is already registered for this subclass.
  # @example
  #   class Role < Anchormodel
  #     attr_reader :privilege_level
  #     new :guest, privilege_level: 0
  #   end
  def initialize(key, **attributes)
    self.class.setup! unless self.class.setup_completed

    @key = key.to_sym
    @index = entries_list.count

    # Save attributes as instance variables
    attributes.each do |k, v|
      instance_variable_set(:"@#{k}", v)
    end

    # Register self
    fail("Duplicate anchor model key #{key.inspect} for #{self.class}.") if entries_hash.key?(key)
    entries_list << self
    entries_hash[key] = self

    # Register valid keys
    valid_keys << key

    # Define boolean reader
    self.class.define_method(:"#{key}?") do
      @key == key
    end
  end

  # Two anchormodels are equal iff they have the same concrete class and key.
  # Different subclasses sharing a key are not equal.
  # @param other [Object]
  # @return [Boolean]
  def ==(other)
    self.class == other.class && key == other.key
  end
  alias eql? ==

  # Hash matches `==` (class + key) so `Set` and `Hash` membership work correctly
  # even for copies (`dup`, Marshal round-trip) of the singleton entries.
  # @return [Integer]
  def hash
    [self.class, key].hash
  end

  # Returns a translatable label for this entry, compatible with the
  # [Rails FastGettext](https://github.com/grosser/gettext_i18n_rails/) gem.
  # The translation key is `"<SubclassName>|<Humanized key>"`.
  # @return [String]
  # @example
  #   Role.find(:admin).label # => "Role|Admin" (or its I18n translation)
  def label
    I18n.t("#{self.class.name.demodulize}|#{key.to_s.humanize}")
  end

  # @return [String] Debug representation like `"#<Role<admin>:HASH>"`.
  def inspect
    "#<#{self.class.name}<#{key}>:#{hash}>"
  end

  # Same as {#inspect}. Anchormodel intentionally overrides `to_s` so string
  # interpolation in templates is unambiguous; render `#label` or `#key` directly
  # if you want a user-facing form.
  # @return [String]
  def to_s
    inspect
  end

  # JSON serialization returns the key as a String so anchormodels round-trip
  # cleanly through JSON (e.g. for API payloads).
  # @return [String]
  # @example
  #   Role.find(:admin).as_json # => "admin"
  def as_json
    key.to_s
  end
end

require 'anchormodel/util'
require 'anchormodel/active_model_type_value_single'
require 'anchormodel/active_model_type_value_multi'
require 'anchormodel/attribute'
require 'anchormodel/model_mixin'
require 'anchormodel/version'
require 'anchormodel/simple_form_inputs/helpers/anchormodel_inputs_common'
require 'anchormodel/simple_form_inputs/anchormodel_input'
require 'anchormodel/simple_form_inputs/anchormodel_radio_buttons_input'
require 'anchormodel/simple_form_inputs/anchormodel_check_boxes_input'
