# @api description
# All Rails models making use of #belongs_to_anchormodel must include this mixin. Typically, it is included in `application_record.rb`.
module Anchormodel::ModelMixin
  extend ActiveSupport::Concern

  included do
    class_attribute :anchormodel_attributes, default: {}.freeze
  end

  class_methods do
    # Creates an attribute linking to an Anchormodel. The attribute should be
    # present in the DB and the column should be of type String and named the same as `attribute_name`.
    # @see Anchormodel::Util#install_methods_in_model Parameters
    def belongs_to_anchormodel(*args, **kwargs)
      Anchormodel::Util.install_methods_in_model(self, *args, **kwargs)
    end

    # Creates an attribute linking to an array of Anchormodels. The attribute should be
    # present in the DB and the column should be named the singular of `attribute_name`.
    # @see Anchormodel::Util#install_methods_in_model Parameters
    def belongs_to_anchormodels(*args, **kwargs)
      Anchormodel::Util.install_methods_in_model(self, *args, **kwargs, multiple: true)
    end
  end
end
