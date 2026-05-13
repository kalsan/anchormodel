class UserTest < Minitest::Test
  def setup; end

  def teardown
    User.destroy_all
  end

  # `find` by Symbol and by String must return the same singleton instance.
  def test_retrieval
    assert_equal Role.find(:guest), Role.find('guest')
  end

  # `Anchormodel.all` preserves declaration order and is isolated per subclass
  # (no cross-class registry pollution).
  def test_collections
    assert_equal(
      %i[guest moderator admin the_chosen_one].map { |key| Role.find(key) },
      Role.all
    )
    assert_equal(
      %i[en de fr it].map { |key| Locale.find(key) },
      Locale.all
    )
  end

  # All three assignment forms are valid: String, Symbol, Anchormodel instance.
  # Reader always returns the Anchormodel instance regardless of input form.
  def test_basic_setters_and_getters
    u = User.create!(role: 'guest', locale: 'de') # String assignment
    assert_equal Role.find(:guest), u.role
    assert_equal Locale.find(:de), u.locale
    u.update!(role: :admin, locale: Locale.find(:en)) # Symbol and Anchormodel assignment
    assert_equal Role.find(:admin), u.role
    assert_equal Locale.find(:en), u.locale
  end

  # `Anchormodel#==` defined class+key equality, but `hash` and `eql?` defaulted to
  # object identity. Worked in practice only because instances are singletons via
  # `entries_hash`. Any non-singleton copy (e.g. `dup`, Marshal round-trip, test doubles)
  # broke `Set`/`Hash` membership and `==` comparison invariants.
  def test_hash_and_eql_match_equality
    admin1 = Role.find(:admin)
    admin2 = admin1.dup

    assert_equal admin1, admin2
    assert_equal admin1.hash, admin2.hash
    assert admin1.eql?(admin2)
    assert admin2.eql?(admin1)

    # Different keys must differ
    refute_equal admin1.hash, Role.find(:guest).hash # rubocop:disable Rails/RefuteMethods

    # Set/Hash membership now consistent with `==`
    assert_equal 1, Set.new([admin1, admin2]).size
    assert_equal 'a', ({ admin1 => 'a' }[admin2])
  end

  # Two users with the same locale yield equal locale instances; different locales differ.
  # Verifies that `==` works through model accessors (not just direct `find` results).
  def test_comparison
    bob = User.create(locale: :en)
    alice = User.create(locale: :fr)
    celine = User.create(locale: :fr)
    assert_equal(alice.locale, celine.locale)
    assert bob.locale != alice.locale
  end

  # Custom attributes declared on the Anchormodel subclass (e.g. `privilege_level` on Role)
  # are accessible both standalone and through the model accessor.
  def test_attributes
    # Standalone
    assert_equal 0, Role.find(:guest).privilege_level
    # With a model
    u = User.create(role: :the_chosen_one)
    assert_equal 42, u.role.privilege_level
  end

  # User-defined `<=>` on the Anchormodel subclass (via `include Comparable`) powers
  # `<`, `>`, `==`, and `<=>` between instances.
  def test_custom_comparison
    assert_equal(-1, Role.find(:moderator) <=> Role.find(:admin))
    assert_equal(1, Role.find(:moderator) <=> Role.find(:guest))
    assert_equal(0, Role.find(:moderator) <=> Role.find('moderator'))
    assert Role.find(:moderator) < Role.find(:admin)
  end

  # `belongs_to_anchormodel :col_name, AnchormodelClass` decouples the DB column name
  # from the anchormodel class — here `:secondary_role` maps to `Role`.
  def test_alternative_column_name
    ben = User.create!(
      role:           Role.find(:moderator),
      secondary_role: Role.find(:admin),
      locale:         Locale.find(:de)
    )
    assert_equal(Role.find(:moderator), ben.role)
    assert_equal(Role.find(:admin), ben.secondary_role)
    assert_equal(Locale.find(:de), ben.locale)
  end

  # `optional: true` permits NULL in the column; reader returns nil rather than raising.
  def test_optional_attribute
    jenny = User.create!(role: :admin, locale: :en)
    assert_nil jenny.secondary_role
  end

  # Auto-generated per-key readers (`pia.admin?`) and writers (`pia.admin!`) installed
  # by `belongs_to_anchormodel` for every key in the anchormodel.
  def test_model_readers_and_writers
    pia = User.new
    pia.admin!
    assert_equal true, pia.admin?
    assert_equal false, pia.guest?
    assert_equal Role.find(:admin), pia.role
  end

  # Auto-generated per-key class scopes (`User.admin`, `User.moderator`, etc.) installed
  # by `belongs_to_anchormodel`.
  def test_model_scopes
    User.create!(role: :admin, locale: :en)
    User.create!(role: :admin, locale: :en)
    User.create!(role: :moderator, locale: :en)
    assert_equal 2, User.admin.count
    assert_equal 1, User.moderator.count
    assert_equal 0, User.guest.count
  end

  # Regression: `where(anchormodel_col: %w[a b])` used to collapse to `IN (NULL)`
  # because `Single#serializable?` was inverted, causing AR's `HomogeneousIn` to
  # filter out all valid keys before binding.
  def test_where_with_array_of_keys
    User.create!(role: :admin, locale: :en)
    User.create!(role: :moderator, locale: :en)
    User.create!(role: :guest, locale: :en)

    sql = User.where(role: %w[admin moderator]).to_sql
    assert_match(/admin/, sql)
    assert_match(/moderator/, sql)
    refute_match(/IN \(NULL\)/i, sql) # rubocop:disable Rails/RefuteMethods

    assert_equal 2, User.where(role: %w[admin moderator]).count
    assert_equal 2, User.where(role: %i[admin moderator]).count
    assert_equal(
      2,
      User.where(role: [Role.find(:admin), Role.find(:moderator)]).count
    )
    assert_equal 1, User.where.not(role: %w[admin moderator]).count
  end

  # Bulk `where` with any unknown key raises immediately rather than silently filtering it out.
  def test_where_with_array_of_invalid_keys_raises
    assert_raises(RuntimeError) { User.where(role: %w[admin nope]).to_a }
  end

  # Single-value anchormodel attributes must reject Array assignment with a clear RuntimeError.
  # Regression: when Array handling was added to `Single#serialize` for the `where(col: array)`
  # fix, it began silently accepting Array writes (e.g. `u.role = %w[admin guest]`) and only
  # blew up later with `NoMethodError: undefined method 'to_sym' for an instance of Array`.
  def test_single_attr_rejects_array_assignment
    u = User.new(role: 'admin', locale: 'de')
    assert_raises(RuntimeError) { u.role = %w[admin guest] }
    assert_raises(RuntimeError) { User.new(role: %w[admin guest], locale: 'de') }
  end

  # Direct probe on `Single#serializable?` — guards against re-introducing the inverted
  # `exclude?` logic that silently dropped valid keys from `HomogeneousIn` binds.
  # Single-value attributes do NOT accept Array values (those are for `belongs_to_anchormodels`),
  # so `serializable?(array)` must return false.
  def test_serializable_predicate
    type = User.type_for_attribute(:role)
    assert type.serializable?('admin')
    assert type.serializable?(:admin)
    assert type.serializable?(Role.find(:admin))
    assert type.serializable?(nil)
    refute type.serializable?(42) # rubocop:disable Rails/RefuteMethods
    refute type.serializable?(%w[admin guest]) # rubocop:disable Rails/RefuteMethods
    refute type.serializable?([:admin, Role.find(:guest)]) # rubocop:disable Rails/RefuteMethods
    refute type.serializable?([42]) # rubocop:disable Rails/RefuteMethods
  end

  # `Multi#serialize` must validate String inputs against valid keys, not pass through verbatim.
  # Old impl returned the raw String unchecked, which corrupted DB rows and deferred errors
  # to the next read.
  def test_multi_serialize_validates_string_input
    type = User.type_for_attribute(:animals)
    assert_equal 'cat',     type.serialize('cat')
    assert_equal 'cat,dog', type.serialize('cat,dog')
    assert_equal '',        type.serialize('')
    assert_raises(RuntimeError) { type.serialize('bogus') }
    assert_raises(RuntimeError) { type.serialize('bogus,nonsense') }
    assert_raises(RuntimeError) { type.serialize('cat,bogus') }
  end

  # Same String-input validation must apply through normal model assignment, not just
  # the type object directly. Verifies constructor, writer, and DB round-trip.
  def test_multi_string_assignment_validates
    # Constructor with valid String
    u = User.create!(role: 'guest', locale: 'de', animals: 'cat,dog')
    assert_equal(Set.new([Animal.find(:cat), Animal.find(:dog)]), u.animals)
    assert_equal(Set.new([Animal.find(:cat), Animal.find(:dog)]), User.first.animals) # round-trip via DB

    # Writer with valid single-key String
    u.animals = 'horse'
    assert_equal(Set.new([Animal.find(:horse)]), u.animals)

    # Writer with invalid String raises immediately, not on next read
    assert_raises(RuntimeError) { u.animals = 'bogus' }
    assert_raises(RuntimeError) { u.animals = 'cat,bogus' }

    # Constructor with invalid String raises immediately
    assert_raises(RuntimeError) { User.new(role: 'guest', locale: 'de', animals: 'bogus,nonsense') }
  end

  # SQL LIKE treats `_` as a single-character wildcard. Keys containing `_` (e.g. `:big_cat`)
  # must be escaped in the per-key scope and in the `with_any_<attr>` helper, or they
  # cross-match arbitrary column values with one character in place of the underscore.
  def test_multi_scope_escapes_underscore_wildcard_in_keys
    # Raw row whose `animals` CSV does NOT contain `big_cat` but does contain a string
    # that an unescaped LIKE pattern (`%big_cat,%`) would match: `bigXcat,foo`.
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      INSERT INTO users (role, locale, preferred_locale, animals, created_at, updated_at)
      VALUES ('guest', 'de', 'de', 'bigXcat,foo', 'now', 'now')
    SQL
    # Baseline row that actually contains :big_cat.
    User.create!(role: 'guest', locale: 'fr', animals: %w[big_cat])

    # Both scope styles must match only the real row, not the look-alike.
    assert_equal 1, User.big_cat.count
    assert_equal 1, User.with_any_animals(:big_cat).count
    assert_equal 1, User.with_all_animals(:big_cat).count
  end

  # `where(multi_col: array)` cannot match CSV-in-column storage. Helper scopes
  # `with_any_<attr>` (OR semantics) and `with_all_<attr>` (AND semantics) provide
  # a working idiom for bulk-key queries.
  def test_multi_helper_scopes_with_any_and_with_all
    u_cat_dog   = User.create!(role: 'guest', locale: 'fr', animals: %w[cat dog])
    u_dog_horse = User.create!(role: 'guest', locale: 'it', animals: %w[dog horse])
    u_cat       = User.create!(role: 'guest', locale: 'de', animals: %w[cat])

    # Plain `where(animals: array)` cannot reliably match CSV-in-column storage —
    # it only catches rows whose entire column value equals one of the given keys.
    # Use `with_any_<attr>` / `with_all_<attr>` instead.
    plain_count  = User.where(animals: %w[cat dog]).count
    helper_count = User.with_any_animals(:cat, :dog).count
    refute_equal plain_count, helper_count, # rubocop:disable Rails/RefuteMethods
                 'plain where(col: array) cannot match CSV-in-column storage; use with_any_<col>'

    # `with_any_<attr>` — users that hold at least one of the given keys.
    assert_equal 3, User.with_any_animals(:cat, :dog).count
    assert_equal 2, User.with_any_animals(:cat).count
    assert_equal 1, User.with_any_animals(:horse).count
    assert_equal 0, User.with_any_animals(:rat).count
    assert_equal 0, User.with_any_animals.count # empty arg list

    # Accepts Strings, Symbols, and Anchormodel instances interchangeably.
    assert_equal 2, User.with_any_animals('cat').count
    assert_equal 2, User.with_any_animals(Animal.find(:cat)).count
    assert_equal 3, User.with_any_animals([:cat, 'dog']).count # flattened

    # `with_all_<attr>` — users that hold every given key.
    assert_equal 1, User.with_all_animals(:cat, :dog).count
    assert_equal 2, User.with_all_animals(:dog).count
    assert_equal 0, User.with_all_animals(:cat, :dog, :rat).count

    # Invalid keys raise immediately.
    assert_raises(RuntimeError) { User.with_any_animals(:bogus).to_a }
    assert_raises(RuntimeError) { User.with_all_animals(:cat, :bogus).to_a }

    # Returned IDs check
    assert_equal [u_cat_dog.id, u_cat.id].sort, User.with_any_animals(:cat).pluck(:id).sort
    assert_equal [u_cat_dog.id, u_dog_horse.id].sort, User.with_any_animals(:dog).pluck(:id).sort
    assert_equal [u_cat_dog.id], User.with_all_animals(:cat, :dog).pluck(:id)
  end

  # `Multi#cast` must tolerate nil — e.g. NULL stored in DB from a migration that did
  # not backfill, or column with no default. Also covers `deserialize(nil)` which falls
  # back to `cast` from `ActiveModel::Type::Value`.
  def test_multi_cast_nil_returns_empty_set
    type = User.type_for_attribute(:animals)
    assert_equal Set.new, type.cast(nil)
    assert_equal Set.new, type.deserialize(nil)
  end

  # `Multi#serializable?` must return strict Boolean (true/false), not a truthy String/Array.
  # Old impl: `values.map { super }.compact.join(',')` etc — returned non-Boolean and was
  # always truthy regardless of element validity.
  def test_multi_serializable_predicate_returns_boolean
    type = User.type_for_attribute(:animals)
    assert_equal true,  type.serializable?(%w[cat dog])
    assert_equal true,  type.serializable?([:cat, Animal.find(:dog)])
    assert_equal true,  type.serializable?(Set.new(%w[cat]))
    assert_equal true,  type.serializable?('cat,dog')
    assert_equal true,  type.serializable?(nil)
    assert_equal false, type.serializable?(42)
    assert_equal false, type.serializable?([42])
    assert_equal false, type.serializable?([:cat, 42])
  end

  # Per-key readers/writers use the anchormodel's own keys (`:de`, `:fr`) even when the
  # model attribute name differs (`preferred_locale` → `Locale`).
  def test_model_readers_writers_with_different_class_name
    pia = User.new(locale: :en)
    pia.de!
    assert_equal true, pia.de?
    assert_equal false, pia.fr?
    assert_equal Locale.find(:de), pia.preferred_locale
    assert_equal Locale.find(:en), pia.locale
  end

  # Per-key scopes use the anchormodel's own keys (`User.de`, `User.fr`) even when the
  # model attribute name differs (`preferred_locale` → `Locale`).
  def test_model_scopes_with_different_class_name
    User.create!(role: :admin, locale: :en, preferred_locale: :de)
    User.create!(role: :admin, locale: :en, preferred_locale: :de)
    User.create!(role: :admin, locale: :en, preferred_locale: :fr)
    assert_equal 2, User.de.count
    assert_equal 1, User.fr.count
    assert_equal 0, User.en.count
  end

  # Empty String is treated as nil — supports default Rails form submissions that send
  # `""` for unset selects on optional attributes.
  def test_rails_blank_assignment
    u = User.new(role: :admin, secondary_role: :admin, locale: :en, preferred_locale: :en)
    u.secondary_role = ''
    assert_nil u.secondary_role
  end

  ###---
  # Testing failures
  ###---

  # A required (non-optional) anchormodel attribute that is unset triggers Rails presence
  # validation on save.
  def test_presence_validation
    valentine = User.new
    assert_raises(ActiveRecord::RecordInvalid) { valentine.save! }
  end

  # `find` with an unregistered key raises `Anchormodel::InvalidKey`.
  def test_missing_key
    assert_raises(Anchormodel::InvalidKey) { Role.find(:does_not_exist) }
  end

  # Callers want to `rescue` invalid-key errors specifically without matching exception
  # message strings. `Anchormodel::InvalidKey` is the dedicated class, raised from every
  # entry point that could encounter an unknown key.
  def test_invalid_key_error_class
    # `find` with unknown key
    assert_raises(Anchormodel::InvalidKey) { Role.find(:nope) }

    # Assignment with unknown key
    u = User.new(locale: 'de')
    assert_raises(Anchormodel::InvalidKey) { u.role = :nope }

    # Bulk where with mixed valid/invalid array
    assert_raises(Anchormodel::InvalidKey) { User.where(role: %w[admin nope]).to_a }

    # Multi attribute assignment with unknown key
    assert_raises(Anchormodel::InvalidKey) { User.new(role: 'admin', locale: 'de', animals: %w[cat nope]) }

    # Helper scope with unknown key
    assert_raises(Anchormodel::InvalidKey) { User.with_any_animals(:nope).to_a }

    # InvalidKey must inherit from StandardError so generic `rescue` catches it
    assert_operator Anchormodel::InvalidKey, :<, StandardError
  end

  # Attempting to create a model with an invalid anchormodel key should fail.
  def test_invalid_key_update
    assert_raises(RuntimeError) { User.create!(role: :admin, locale: :de, preferred_locale: :invalid) }
  end

  # Attempting to assign an invalid anchormodel key to a model attribute should fail.
  def test_invalid_key_assignment
    assert_raises(RuntimeError) { User.new(role: :invalid) }
  end

  # An invalid anchormodel key sneaked into the DB raises on read (via `cast` → `find`).
  def test_invalid_db_read
    sql = <<~SQL.squish
      INSERT INTO users (role, locale, preferred_locale, created_at, updated_at) VALUES ('invalid', 'de', 'de', 'now', 'now')
    SQL
    ActiveRecord::Base.connection.execute(sql)
    assert_raises(RuntimeError) { User.first.role }
  end

  ###---
  # Testing multiple anchormodel associations
  ###---

  # Multi attribute full lifecycle: empty default, `<<`, `add` with String/Symbol/instance,
  # `delete` with String/Symbol/instance, mass `=`, and `clear`.
  def test_multi_basics
    u = User.create!(role: 'guest', locale: 'de')
    assert_equal(Set.new, u.animals)
    # Adding
    u.animals << 'cat'
    assert_equal(Set.new([Animal.find(:cat)]), u.animals)
    u.animals.add :dog
    assert_equal(Set.new([Animal.find(:cat), Animal.find(:dog)]), u.animals)
    u.animals.add Animal.find(:horse)
    assert_equal(Set.new([Animal.find(:cat), Animal.find(:dog), Animal.find(:horse)]), u.animals)
    # Removing
    u.animals.delete 'cat'
    assert_equal(Set.new([Animal.find(:dog), Animal.find(:horse)]), u.animals)
    u.animals.delete :dog
    assert_equal(Set.new([Animal.find(:horse)]), u.animals)
    u.animals.delete Animal.find(:horse)
    assert_equal(false, u.animals.any?)
    # Setting
    u.animals = %i[cat dog]
    assert_equal(Set.new([Animal.find(:cat), Animal.find(:dog)]), u.animals)
    # Clearing
    u.animals.clear
    assert_equal(false, u.animals.any?)
  end

  # Round-trip through the database preserves the Set of anchormodels (write CSV → read CSV → Set).
  def test_multi_save_load
    u = User.create!(role: 'guest', locale: 'de')
    u.animals = %i[cat dog]
    u.save!
    freshly_loaded_u = User.first
    assert_equal(Set.new([Animal.find(:cat), Animal.find(:dog)]), freshly_loaded_u.animals)
  end

  # Per-key readers (`u.cat?`) and writers (`u.cat!`) work for multi attributes.
  # `cat!` is idempotent — Set-based storage prevents duplicates.
  def test_multi_model_readers_and_writers
    u = User.create!(role: 'guest', locale: 'de')
    u.cat!
    u.cat!
    assert_equal(Set.new([Animal.find(:cat)]), u.animals) # tolerate no duplicate cat
    assert_equal(true, u.cat?)
    u.dog!
    assert_equal(true, u.cat?)
    assert_equal(true, u.dog?)
    assert_equal(false, u.horse?)
  end

  # Per-key scopes (`User.cat`, `User.dog`) work for multi attributes via the
  # CSV-contains LIKE predicate (`Anchormodel::Util.csv_contains_like`).
  def test_multi_model_scopes
    u = User.create!(role: 'guest', locale: 'fr', animals: %w[dog cat])
    v = User.create!(role: 'guest', locale: 'it', animals: %w[dog horse])
    assert_equal(0, User.rat.count)
    assert_equal(1, User.cat.count)
    assert_equal(1, User.horse.count)
    assert_equal(2, User.dog.count)
    assert_equal(u.id, User.cat.first.id)
    assert_equal(v.id, User.horse.first.id)
  end
end
