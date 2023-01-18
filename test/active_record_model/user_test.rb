class UserTest < Minitest::Test
  def setup; end

  def test_create
    User.create!(role: 'guest', locale: 'de')
    assert_equal Role.find(:guest), User.first.role
  end
end