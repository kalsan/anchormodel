class AnchormodelGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def add_anchormodel
    fail('NAME must be present.') if name.blank?
    @klass = @name.camelize
    @filename = @name.underscore

    template 'anchormodel.rb.erb', "app/anchormodels/#{@filename}.rb"
  end
end
