class ApplicationRecord < ActiveRecord::Base
  include Anchormodel::ModelMixin

  primary_abstract_class
end
