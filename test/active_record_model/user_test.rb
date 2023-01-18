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
    bob = User.create(role: :guest, locale: :en)
    alice = User.create(role: :guest, locale: :fr)
    assert_equal(bob.role, alice.role)
    assert bob.locale != alice.locale
  end
end
