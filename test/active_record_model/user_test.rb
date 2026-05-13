class UserTest < Minitest::Test
  def setup; end

  def teardown
    User.destroy_all
  end

  def test_retrieval
    assert_equal Role.find(:guest), Role.find('guest')
  end

  def test_collections
    # Order must fit as well
    assert_equal(
      %i[guest moderator admin the_chosen_one].map { |key| Role.find(key) },
      Role.all
    )
    assert_equal(
      %i[en de fr it].map { |key| Locale.find(key) },
      Locale.all
    )
  end

  def test_basic_setters_and_getters
    u = User.create!(role: 'guest', locale: 'de') # String assignment
    assert_equal Role.find(:guest), u.role
    assert_equal Locale.find(:de), u.locale
    u.update!(role: :admin, locale: Locale.find(:en)) # Symbol and Anchormodel assignemnt
    assert_equal Role.find(:admin), u.role
    assert_equal Locale.find(:en), u.locale
  end

  def test_comparison
    bob = User.create(locale: :en)
    alice = User.create(locale: :fr)
    celine = User.create(locale: :fr)
    assert_equal(alice.locale, celine.locale)
    assert bob.locale != alice.locale
  end

  def test_attributes
    # Standalone
    assert_equal 0, Role.find(:guest).privilege_level
    # With a model
    u = User.create(role: :the_chosen_one)
    assert_equal 42, u.role.privilege_level
  end

  def test_custom_comparison
    assert_equal(-1, Role.find(:moderator) <=> Role.find(:admin))
    assert_equal(1, Role.find(:moderator) <=> Role.find(:guest))
    assert_equal(0, Role.find(:moderator) <=> Role.find('moderator'))
    assert Role.find(:moderator) < Role.find(:admin)
  end

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

  def test_optional_attribute
    jenny = User.create!(role: :admin, locale: :en)
    assert_nil jenny.secondary_role
  end

  def test_model_readers_and_writers
    pia = User.new
    pia.admin!
    assert_equal true, pia.admin?
    assert_equal false, pia.guest?
    assert_equal Role.find(:admin), pia.role
  end

  def test_model_scopes
    User.create!(role: :admin, locale: :en)
    User.create!(role: :admin, locale: :en)
    User.create!(role: :moderator, locale: :en)
    assert_equal 2, User.admin.count
    assert_equal 1, User.moderator.count
    assert_equal 0, User.guest.count
  end

  # Regression: `where(anchormodel_col: %w[a b])` used to collapse to `IN (NULL)`
  # because Single#serialize lacked Array handling. See memory `array-where-collapses-to-null`.
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

  def test_where_with_array_of_invalid_keys_raises
    assert_raises(RuntimeError) { User.where(role: %w[admin nope]).to_a }
  end

  # Direct probe on `serializable?` — guards against re-introducing the inverted
  # `exclude?` logic that silently dropped valid keys from `HomogeneousIn` binds.
  def test_serializable_predicate
    type = User.type_for_attribute(:role)
    assert type.serializable?('admin')
    assert type.serializable?(:admin)
    assert type.serializable?(Role.find(:admin))
    assert type.serializable?(nil)
    assert type.serializable?(%w[admin guest])
    assert type.serializable?([:admin, Role.find(:guest)])
    refute type.serializable?(42) # rubocop:disable Rails/RefuteMethods
    refute type.serializable?([42]) # rubocop:disable Rails/RefuteMethods
  end

  # Multi#serializable? must return strict Boolean (true/false), not a truthy String/Array.
  # Old impl: `values.map { super }.compact.join(',')` etc — returned non-Boolean and was
  # always truthy regardless of validity.
  # Multi#cast must tolerate nil — e.g. NULL stored in DB from a migration that did not backfill,
  # or column with no default. Also covers `deserialize(nil)` which falls back to `cast`.
  # Multi#serialize must validate String inputs against valid keys, not pass through verbatim.
  # Old impl returned the raw String unchecked, which corrupted DB rows and deferred errors to the next read.
  def test_multi_serialize_validates_string_input
    type = User.type_for_attribute(:animals)
    assert_equal 'cat',     type.serialize('cat')
    assert_equal 'cat,dog', type.serialize('cat,dog')
    assert_equal '',        type.serialize('')
    assert_raises(RuntimeError) { type.serialize('bogus') }
    assert_raises(RuntimeError) { type.serialize('bogus,nonsense') }
    assert_raises(RuntimeError) { type.serialize('cat,bogus') }
  end

  # Same protection must apply through normal model assignment, not just the type object directly.
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

  # SQL LIKE treats `_` as a single-character wildcard. Keys containing `_` must be escaped
  # in the per-key scope and in the `with_any_<attr>` helper, or they cross-match arbitrary
  # column values with one character in place of the underscore.
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

  # `where(multi_col: array)` cannot match CSV-in-column storage. Helper scopes provide
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

  def test_multi_cast_nil_returns_empty_set
    type = User.type_for_attribute(:animals)
    assert_equal Set.new, type.cast(nil)
    assert_equal Set.new, type.deserialize(nil)
  end

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

  def test_model_readers_writers_with_different_class_name
    pia = User.new(locale: :en)
    pia.de!
    assert_equal true, pia.de?
    assert_equal false, pia.fr?
    assert_equal Locale.find(:de), pia.preferred_locale
    assert_equal Locale.find(:en), pia.locale
  end

  def test_model_scopes_with_different_class_name
    User.create!(role: :admin, locale: :en, preferred_locale: :de)
    User.create!(role: :admin, locale: :en, preferred_locale: :de)
    User.create!(role: :admin, locale: :en, preferred_locale: :fr)
    assert_equal 2, User.de.count
    assert_equal 1, User.fr.count
    assert_equal 0, User.en.count
  end

  def test_rails_blank_assignment
    u = User.new(role: :admin, secondary_role: :admin, locale: :en, preferred_locale: :en)
    u.secondary_role = ''
    assert_nil u.secondary_role
  end

  ###---
  # Testing failures
  ###---

  def test_presence_validation
    valentine = User.new
    assert_raises(ActiveRecord::RecordInvalid) { valentine.save! }
  end

  def test_missing_key
    assert_raises { Role.find(:does_not_exist) }
  end

  # Attempting to create a model with an invalid constant name should fail
  def test_invalid_key_update
    assert_raises(RuntimeError) { User.create!(role: :admin, locale: :de, preferred_locale: :invalid) }
  end

  # Attempting to assign an invalid constant name to a model should fail
  def test_invalid_key_assignment
    assert_raises(RuntimeError) { User.new(role: :invalid) }
  end

  # An invalid constant name into the DB should raise when reading
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

  def test_multi_save_load
    u = User.create!(role: 'guest', locale: 'de')
    u.animals = %i[cat dog]
    u.save!
    freshly_loaded_u = User.first
    assert_equal(Set.new([Animal.find(:cat), Animal.find(:dog)]), freshly_loaded_u.animals)
  end

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
