class User < ApplicationRecord
  belongs_to_anchormodel :role
  belongs_to_anchormodel :locale
end
