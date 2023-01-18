class Role < Anchormodel
  include Comparable

  attr_reader :privilege_level

  new :guest, privilege_level: 0
  new :moderator, privilege_level: 1
  new :admin, privilege_level: 2
  new :the_chosen_one, privilege_level: 42

  def <=>(other)
    @privilege_level <=> other.privilege_level
  end
end
