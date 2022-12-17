class Anchormodel::Attribute
  attr_reader :attribute_name
  attr_reader :optional

  def initialize(model_class, attribute_name, anchor_class_name=nil, optional=false)
    @model_class = model_class
    @attribute_name = attribute_name.to_sym
    @anchor_class_name = anchor_class_name || "Anchormodels::#{attribute_name.to_s.classify}"
    @optional = optional
  end

  # Lazy anchor class loading, because the model mixin instanciates this statically -> avoid premature anchor class loading
  def anchor_class
    @anchor_class ||= @anchor_class_name.constantize
  end
end
