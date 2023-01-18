<img src="logo.svg" height=250 alt="Anchormodel logo"/>

# Introducing Anchormodel

This gem provides a simple but powerful alternative to [Rails
Enums](https://api.rubyonrails.org/v7.0/classes/ActiveRecord/Enum.html). In
contrast to regular Enums, Anchormodels can hold application logic, making them
ideal for tying code to database objects.

# Use case

Typically, a Rails application consists of three kinds of state:

- The code, which we can consider static within a given version. Code can
  reference to other code, e.g. `node.parent = other_node`.
- The database contents, which can fluctuate within the bounds of the DB schema.
  Data can reference to other data, ideally via foreign keys.
- A mix of the two, where code needs to be specifically tailored for some kind
  of data. A prominent example of such a mix would for instance be user roles:
  roles must be hardcoded in the code because security logic is tied to them.
  However, as users are assigned to roles in the database, roles also need to be
  persisted in the database. This is where Anchormodel comes into play.

## Alternatives coviering the same use case

### Enum

In Rails and other frameworks, the third point in the listing above is typically
achieved via Enums. Enums map either Integers or Strings to constants and
therefore provide a link between the DB and the application code.

However, at least in Rails, Enums provide very limited customization options.
They are basic values that can be used in if-statements. Anchormodels however
are regular classes and can easily be extended.

### ActiveEnum

The gem (ActiveEnum)[https://github.com/adzap/active_enum] allows to create
Enum-like classes that can be extended. However it only supports Integer keys. I
find this unsatisfactory, as debugging with tools like `psql` or `mysql` is made
unnecessarily hard when you only see numbers. Keys for enums should be
meaningful, making you immediately understand what they stand for.

This is why Anchormodel is strictly relying on String keys corresponding to the
entries of an Anchormodel.

# Example

`app/anchormodels/role.rb`:

```ruby
class Role < Anchormodel
  # Expose the attribute privilege_level
  attr_reader :privilege_level

  # Overload <=> to make user roles comparable based on the privilege level
  def <=>(other)
    other.privilege_level <=> @privilege_level
  end

  # Declare all available roles
  new :guest, privilege_level: 0
  new :manager, privilege_level: 1
  new :admin, privilege_level: 2
end
```

`app/models/user.rb`

```ruby
# The DB table `users` must have a String column `users.role`
class User < ApplicationRecord
  belongs_to_anchormodel :role
end
```

You may now use the following methods:

```ruby
# Retrieve all user roles:
Role.all

# Retrieve a specific role from the String and find its privilege level
Role.find(:guest).privilege_level

# Implement a Rails helper that makes sure users can only edit other users that have a lower privilege level than themselves
def user_can_edit?(this_user, other_user)
  this_user.role.privilege_level > other_user.role.privilege_level
end

# Pretty print a user's role, e.g. using the Rails FastGettext gem:
puts("User #{@user.name} has role #{@user.role.label}")
```

# Installation

1. Add gem to Gemfile: `gem 'anchormodel'`
2. In `application_record.rb`, add in the class body: `include Anchormodel::ModelMixin`