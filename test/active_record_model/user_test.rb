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
  end
end
