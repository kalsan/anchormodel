class Anchormodel::ActiveModelTypeValue < ActiveModel::Type::Value
  def initialize(attribute)
    @attribute = attribute
  end
end
