class User < ApplicationRecord
  belongs_to_anchormodel :role
  belongs_to_anchormodel :secondary_role, Role, optional: true, model_readers: false, model_writers: false, model_scopes: false
  belongs_to_anchormodel :locale, model_methods: false
  belongs_to_anchormodel :preferred_locale, Locale
end
