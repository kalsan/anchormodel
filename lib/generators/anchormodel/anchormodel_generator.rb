# Rails generator for scaffolding a new anchormodel.
#
# @example
#   rails generate anchormodel Role
#   # → creates app/anchormodels/role.rb
class AnchormodelGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  # Writes the new anchormodel file from the ERB template.
  # @return [void]
  # @raise [RuntimeError] if NAME is blank.
  def add_anchormodel
    fail('NAME must be present.') if name.blank?
    @klass = @name.camelize
    @filename = @name.underscore

    template 'anchormodel.rb.erb', "app/anchormodels/#{@filename}.rb"
  end
end
