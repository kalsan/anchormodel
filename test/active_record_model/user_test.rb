class UserTest < Minitest::Test
  def setup; end

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

  def test_setters_and_getters
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
    assert_equal(1, Role.find(:moderator) <=> Role.find(:admin))
    assert_equal(-1, Role.find(:moderator) <=> Role.find(:guest))
    assert_equal(0, Role.find(:moderator) <=> Role.find(:moderator))
  end
end
