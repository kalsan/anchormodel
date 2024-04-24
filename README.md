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

The gem [ActiveEnum](https://github.com/adzap/active_enum) allows to create
Enum-like classes that can be extended. However it only supports Integer keys. I
find this unsatisfactory, as debugging with tools like `psql` or `mysql` is made
unnecessarily hard when you only see numbers. Keys for enums should be
meaningful, making you immediately understand what they stand for.

This is why Anchormodel is strictly relying on String keys corresponding to the
entries of an Anchormodel.


# Installation

1. Add gem to Gemfile: `gem 'anchormodel'`
2. In `application_record.rb`, add in the class body: `include Anchormodel::ModelMixin`

# Generator

For convenience, Anchormodel provides a Rails generator:

`rails generate anchormodel Role`

This will create `app/anchormodels/role.rb`.

# Basic example

`app/anchormodels/role.rb`:

```ruby
class Role < Anchormodel
  # Make <, > etc. based on <=> operator whic hwe will define below
  include Comparable

  # Expose the attribute privilege_level
  attr_reader :privilege_level

  # Define <=> to make user roles comparable based on the privilege level
  def <=>(other)
    @privilege_level <=> other.privilege_level
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
  # If `users.role` has an `NOT NULL` constraint, use:
  belongs_to_anchormodel :role

  # If `users.role` can be `NULL`, use the following instead:
  belongs_to_anchormodel :role, optional: true
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

# Check whether @user has role admin
@user.role.admin? # true if and only if the role is admin (false otherwise)
```

Your form could look something like this:

```erb
<%= form_with(model: user) do |form| %>
  <%# ... %>
  <%= form.collection_select :role, Role.all, :key, :label %>
  <%# ... %>
<% end %>
```

## Using Anchormodel with Simpleform

Anchormodel has built-in support for the [simple_form](https://github.com/heartcombo/simple_form) gem by providing an input for the type `:anchormodel` which displays anchormodel attributes as a collection select.

After SimpleForm is installed, you can write your form as:

```erb
<%= simple_form_for user do |f| %>
  <%# ... %>
  <%= f.input :role %>
  <%# ... %>
<% end %>
```

Or, if you prefer radio buttons instead:


```erb
<%= simple_form_for user do |f| %>
  <%# ... %>
  <%= f.input :role, as: :anchormodel_radio_buttons %>
  <%# ... %>
<% end %>
```

# Rails Enum style model methods

By default, Anchormodel adds three kinds of methods for each key to the model:

- a reader (getter)
- a writer (setter)
- a Rails scope

For instance:

```ruby
class User < ApplicationRecord
  belongs_to_anchormodel :role # where Role has keys :guest, :manager and :admin
  belongs_to_anchormodel :shape # where Shape has keys :circle and :rectangle
end

# User now implements the following methods, given that @user is retrieved as follows:
@user = User.first # for example

# Readers
@user.guest? # same as @user.role.guest?
@user.manager?
@user.admin?
@user.rectangle? # same as @user.shape.rectangle?
@user.circle?
# Writers
@user.guest! # same as @user.role = Role.find(:guest)
@user.manager!
@user.admin!
@user.rectangle! # same as @user.shape = Shape.find(:rectangle)
@user.circle!
# Scopes
User.guest # same as User.where(role: 'guest')
User.manager
User.admin
User.rectangle # same as User.where(shape: 'rectangle')
User.circle
```

This behavior is similar as the one from Rails Enums. If you want to disable it, use:

```ruby
class User < ApplicationRecord
  belongs_to_anchormodel :role, model_readers: false, model_writers: false, model_scopes: false
  # or, equivalent, to disable all at once:
  belongs_to_anchormodel :role, model_methods: false
end
```

# Calling a column differently than the Anchormodel

If your column name (and the model's attribute) is called differently than the Anchormodel, you may give the Anchormodel's class as the second argument. For example:

```ruby
# app/anchormodels/color.rb
class Color < Anchormodel
  new :green
  new :red
end

# app/models/user.rb
class User < ApplicationRecord
  belongs_to_anchormodel :favorite_color, Color
end
```

## Having multiple attributes to the same Anchormodel

If you want to have multiple attributes in the same model pointing to the same Anchormodel, you need to disable `model_methods` for at least one of them (otherwise the model methods will clash in your model class):

```ruby
# app/models/user.rb
  belongs_to_anchormodel :role
  belongs_to_anchormodel :secondary_role, Role, model_methods: false
```