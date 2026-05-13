# Internal utilities used by the {Anchormodel::ModelMixin#belongs_to_anchormodel} and
# {Anchormodel::ModelMixin#belongs_to_anchormodels} macros. The public-facing entry
# points are the macros themselves; methods here are the wiring that installs the
# generated readers, writers, scopes, type casters, and helper scopes.
module Anchormodel::Util
  # Installs an anchormodel attribute in a model class. Wires up the AR `attribute`
  # type cast, the custom reader/writer, the per-key readers/writers/scopes, and (for
  # `belongs_to_anchormodels`) the bulk-key `with_any_<attr>` / `with_all_<attr>` scopes.
  #
  # Called from {Anchormodel::ModelMixin#belongs_to_anchormodel} and
  # {Anchormodel::ModelMixin#belongs_to_anchormodels}. Not normally invoked directly.
  #
  # @param model_class [Class] Internal only. The model class the attribute is installed on.
  # @param attribute_name [String,Symbol] The name and database column of the attribute.
  # @param anchormodel_class [Class,nil] The anchormodel class. If omitted, inferred from
  #   `attribute_name` (`:foo_bar` → `FooBar`).
  # @param optional [Boolean] If false, a presence validation is added to the model. Forced
  #   to true when `multiple` is true.
  # @param multiple [Boolean] Internal only. Distinguishes between `belongs_to_anchormodel`
  #   (false) and `belongs_to_anchormodels` (true).
  # @param model_readers [Boolean] If true, generates `model.key?` readers per anchormodel key.
  # @param model_writers [Boolean] If true, generates `model.key!` writers per anchormodel key.
  # @param model_scopes [Boolean] If true, generates `Model.key` scopes per anchormodel key.
  # @param model_methods [Boolean,nil] If non-nil, mass-overrides `model_readers`/`model_writers`/`model_scopes`.
  # @return [void]
  # @raise [RuntimeError] if a generated method or scope name collides with an existing one.
  def self.install_methods_in_model(model_class, attribute_name, anchormodel_class = nil,
                                    optional: false,
                                    multiple: false,
                                    model_readers: true,
                                    model_writers: true,
                                    model_scopes: true,
                                    model_methods: nil)

    optional = true if multiple
    anchormodel_class ||= attribute_name.to_s.classify.constantize
    attribute_name = attribute_name.to_sym
    attribute = Anchormodel::Attribute.new(model_class, attribute_name, anchormodel_class, optional, multiple)

    # Mass configurations if model_methods was specfied
    unless model_methods.nil?
      model_readers = model_methods
      model_writers = model_methods
      model_scopes = model_methods
    end

    # Register attribute
    model_class.anchormodel_attributes = model_class.anchormodel_attributes.merge({ attribute_name => attribute }).freeze

    # Add presence validation if required
    unless optional
      model_class.validates attribute_name, presence: true
    end

    # Make casting work
    # Define serializer/deserializer
    active_model_type_value = (multiple ? Anchormodel::ActiveModelTypeValueMulti : Anchormodel::ActiveModelTypeValueSingle).new(attribute)

    # Overwrite reader to force building anchors at every retrieval
    model_class.define_method(attribute_name.to_s) do
      # This patch fixes an issue in combination with the active_type gem, causing virtual models to always read nil on anchormodel attributes.
      raw_data = if defined?(ActiveType::Object) && is_a?(ActiveType::Object)
                   virtual_attributes[attribute_name.to_s]
                 else
                   read_attribute_before_type_cast(attribute_name)
                 end
      result = active_model_type_value.deserialize(raw_data)

      # If this attribute holds multiple anchormodels (`belongs_to_anchormodels`), patch the Array before returning in order to implement collection modifiers:
      if multiple
        model = self # fetching the model in order to pass it to the implementation of the following via reflection to make it available for storage
        single_tv = Anchormodel::ActiveModelTypeValueSingle.new(attribute) # Used for casting inputs to properly compare them to the set.

        # Adding
        result.define_singleton_method('add') do |value_to_add|
          super(single_tv.cast(value_to_add))
          model.write_attribute(attribute_name, active_model_type_value.serialize(self))
          next self
        end
        result.define_singleton_method('<<') { |value_to_add| add(single_tv.cast(value_to_add)) }

        # Deleting
        result.define_singleton_method('delete') do |value_to_delete|
          super(single_tv.cast(value_to_delete))
          model.write_attribute(attribute_name, active_model_type_value.serialize(self))
          next self
        end

        # Clearing
        result.define_singleton_method('clear') do
          super()
          model.write_attribute(attribute_name, active_model_type_value.serialize(self))
          next self
        end

        # In the future, further methods could be supported. e.g. delete_if, subtract etc.
      end

      return result
    end

    # Override writer to fail early when an invalid target value is specified
    model_class.define_method("#{attribute_name}=") do |new_value|
      write_attribute(attribute_name, active_model_type_value.serialize(new_value))
    end

    # Supply serializer and deserializer
    model_class.attribute attribute_name, active_model_type_value

    # Create ActiveRecord::Enum style reader directly in the model if asked to do so
    # For a model User with anchormodel Role with keys :admin and :guest, this creates user.admin? and user.guest? (returning true iff role is admin/guest)
    if model_readers
      anchormodel_class.all.each do |entry|
        if model_class.respond_to?(:"#{entry.key}?")
          fail("Anchormodel reader #{entry.key}? already defined for #{self}, add `model_readers: false` to `belongs_to_anchormodel :#{attribute_name}`.")
        end
        model_class.define_method(:"#{entry.key}?") do
          if multiple
            public_send(attribute_name.to_s).include?(entry)
          else
            public_send(attribute_name.to_s) == entry
          end
        end
      end
    end

    # Create ActiveRecord::Enum style writer directly in the model if asked to do so
    # For a model User with anchormodel Role with keys :admin and :guest, this creates user.admin! and user.guest! (setting the role to admin/guest)
    if model_writers
      anchormodel_class.all.each do |entry|
        if model_class.respond_to?(:"#{entry.key}!")
          fail("Anchormodel writer #{entry.key}! already defined for #{self}, add `model_writers: false` to `belongs_to_anchormodel :#{attribute_name}`.")
        end
        model_class.define_method(:"#{entry.key}!") do
          if multiple
            public_send(attribute_name.to_s) << entry
          else
            public_send(:"#{attribute_name}=", entry)
          end
        end
      end
    end

    # Create ActiveRecord::Enum style scope directly in the model class if asked to do so
    # For a model User with anchormodel Role with keys :admin and :guest, this creates User.admin and User.guest scopes
    if model_scopes
      anchormodel_class.all.each do |entry|
        if model_class.respond_to?(entry.key)
          fail("Anchormodel scope #{entry.key} already defined for #{self}, add `model_scopes: false` to `belongs_to_anchormodel :#{attribute_name}`.")
        end
        if multiple
          sql, *binds = Anchormodel::Util.csv_contains_like(attribute_name, entry.key)
          model_class.scope(entry.key, -> { where(sql, *binds) })
        else
          model_class.scope(entry.key, -> { where(attribute_name => entry.key) })
        end
      end
    end

    # For `belongs_to_anchormodels`, add bulk-key scopes since `where(col: array)` cannot
    # match CSV-in-column storage. Defined regardless of `model_scopes` — they are bulk
    # query helpers, not per-key scopes.
    if multiple
      model_class.scope(:"with_any_#{attribute_name}", lambda do |*keys|
        keys = Anchormodel::Util.normalize_anchormodel_keys(keys, anchormodel_class)
        next none if keys.empty?

        clauses = keys.map { |k| Anchormodel::Util.csv_contains_like(attribute_name, k) }
        sql = clauses.map { |c| "(#{c.first})" }.join(' OR ')
        binds = clauses.flat_map { |c| c.drop(1) }
        where(sql, *binds)
      end)

      model_class.scope(:"with_all_#{attribute_name}", lambda do |*keys|
        keys = Anchormodel::Util.normalize_anchormodel_keys(keys, anchormodel_class)
        next all if keys.empty?

        keys.reduce(all) { |rel, k| rel.merge(public_send(:"with_any_#{attribute_name}", k)) }
      end)
    end
  end

  # Coerces a list of mixed-type key inputs into validated key Strings, ready for SQL binding.
  # Accepts Strings, Symbols, Anchormodel instances, and arbitrarily nested arrays of those.
  #
  # @param keys [Array] Input list (flattened internally).
  # @param anchormodel_class [Class] The anchormodel class against which keys are validated.
  # @return [Array<String>] Flattened, stringified, validated keys.
  # @raise [Anchormodel::InvalidKey] if any element is not a registered key.
  # @example
  #   Anchormodel::Util.normalize_anchormodel_keys([:cat, 'dog', Animal.find(:horse)], Animal)
  #   # => ["cat", "dog", "horse"]
  def self.normalize_anchormodel_keys(keys, anchormodel_class)
    keys = keys.flatten.map { |k| k.respond_to?(:key) ? k.key.to_s : k.to_s }
    keys.each { |k| anchormodel_class.find(k) }
    keys
  end

  # Builds a `WHERE` fragment matching rows whose CSV-stored `attribute` column contains
  # `key`. Generates four predicates OR'd together to cover the cases where `key` appears
  # at the start, end, middle, or as the sole entry in the CSV.
  #
  # `_` and `%` characters in `key` are escaped via `ESCAPE '!'` so that LIKE wildcards
  # in the key (e.g. `:big_cat`) are treated literally instead of cross-matching arbitrary
  # column values like `"bigXcat,foo"`.
  #
  # @param attribute [String,Symbol] Column name to query.
  # @param key [String,Symbol] Key to search for inside the CSV column value.
  # @return [Array(String, *String)] `[sql_fragment, *bind_values]`, suitable for splatting
  #   into `Model.where(sql, *binds)`.
  # @example
  #   sql, *binds = Anchormodel::Util.csv_contains_like(:animals, :cat)
  #   User.where(sql, *binds)
  def self.csv_contains_like(attribute, key)
    escaped = escape_like(key.to_s)
    sql = "#{attribute} = ? OR #{attribute} LIKE ? ESCAPE '!' " \
          "OR #{attribute} LIKE ? ESCAPE '!' OR #{attribute} LIKE ? ESCAPE '!'"
    binds = [key.to_s, "#{escaped},%", "%,#{escaped}", "%,#{escaped},%"]
    [sql, *binds]
  end

  # Escapes `_`, `%`, and `!` so the string can be used as a literal inside a SQL `LIKE`
  # pattern paired with `ESCAPE '!'`. Uses `!` rather than the conventional `\` to avoid
  # the cross-DB ambiguity of backslash inside SQL string literals (SQLite vs MySQL vs
  # PostgreSQL all differ).
  #
  # @param str [String,Symbol] Input to escape.
  # @return [String] Escaped string.
  # @example
  #   Anchormodel::Util.escape_like('big_cat') # => "big!_cat"
  def self.escape_like(str)
    str.to_s.gsub(/[!%_]/) { |c| "!#{c}" }
  end
end
