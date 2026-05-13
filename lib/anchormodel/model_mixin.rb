# Include this mixin in every Rails model that uses anchormodel attributes. The common
# pattern is to include it once in `application_record.rb` so all descendant models pick
# it up automatically.
#
# Adds two class-level macros:
# - {ClassMethods#belongs_to_anchormodel} for single-value attributes
# - {ClassMethods#belongs_to_anchormodels} for collection-valued attributes
#
# @example Install in ApplicationRecord
#   class ApplicationRecord < ActiveRecord::Base
#     include Anchormodel::ModelMixin
#   end
module Anchormodel::ModelMixin
  extend ActiveSupport::Concern

  included do
    # @!attribute [rw] anchormodel_attributes
    #   @return [Hash{Symbol => Anchormodel::Attribute}] All anchormodel attributes
    #     declared on this model class, keyed by attribute name.
    class_attribute :anchormodel_attributes, default: {}.freeze
  end

  class_methods do
    # Declares a single-value anchormodel attribute.
    #
    # The DB table must have a String column with the same name as `attribute_name`.
    # @see Anchormodel::Util.install_methods_in_model Full parameter documentation.
    # @example Basic usage
    #   class User < ApplicationRecord
    #     belongs_to_anchormodel :role               # `Role` inferred from attribute name
    #     belongs_to_anchormodel :role, optional: true
    #     belongs_to_anchormodel :favorite_color, Color   # explicit anchormodel class
    #   end
    def belongs_to_anchormodel(*args, **kwargs)
      Anchormodel::Util.install_methods_in_model(self, *args, **kwargs)
    end

    # Declares a collection-valued anchormodel attribute.
    #
    # The DB table must have a String column with the same name as `attribute_name`.
    # Multiple keys are stored as a comma-separated string. Reading the attribute returns
    # a `Set` of Anchormodel instances. `optional: true` is forced (an empty collection
    # is a valid value).
    #
    # @see Anchormodel::Util.install_methods_in_model Full parameter documentation.
    # @example Basic usage
    #   class User < ApplicationRecord
    #     belongs_to_anchormodels :animals
    #   end
    #
    #   user = User.create!(animals: %i[cat dog])
    #   user.animals                  # => #<Set: {#<Animal<cat>>, #<Animal<dog>>}>
    #   user.cat?                     # => true
    #   user.animals << :horse
    #   User.with_any_animals(:cat, :horse) # => relation matching the user above
    def belongs_to_anchormodels(*args, **kwargs)
      Anchormodel::Util.install_methods_in_model(self, *args, **kwargs, multiple: true)
    end
  end
end
