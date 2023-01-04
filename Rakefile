require 'bundler/gem_tasks'
require_relative 'lib/anchormodel/version'

task :gemspec do
  specification = Gem::Specification.new do |s|
    s.name = 'anchormodel'
    s.version = Anchormodel::Version::LABEL
    s.author = ['Sandro Kalbermatter']
    s.summary = 'Bringing object-oriented programming to Rails enums'
    s.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
    s.executables   = []
    s.require_paths = ['lib']
    s.required_ruby_version = '>= 3.0.0'
    s.license = 'LGPL-3.0-or-later'
    s.homepage = 'https://github.com/kalsan/anchormodel'

    # Dependencies
    s.add_runtime_dependency 'rails', '~> 7.0'

    s.add_development_dependency 'yard', '~> 0.9.28'
    s.add_development_dependency 'yard-activesupport-concern', '~> 0.0.1'
  end

  File.open('anchormodel.gemspec', 'w') do |f|
    f.puts('# DO NOT EDIT')
    f.puts("# This file is auto-generated via: 'rake gemspec'.\n\n")
    f.write(specification.to_ruby.strip)
  end
end
