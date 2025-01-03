require 'bundler/gem_tasks'
require_relative 'lib/anchormodel/version'

# Create "gemspec" task
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
    s.add_runtime_dependency 'rails', '>= 7.0'

    s.add_development_dependency 'rake', '~> 13.0.6'
    s.add_development_dependency 'pry', '~> 0.14.1'

    # Linter
    s.add_development_dependency 'rubocop', '~> 1.43.0'
    s.add_development_dependency 'rubocop-rails', '~> 2.17.4'

    # Doc
    s.add_development_dependency 'yard', '~> 0.9.28'
    s.add_development_dependency 'yard-activesupport-concern', '~> 0.0.1'

    # Test
    s.add_development_dependency 'minitest', '~> 5.17.0'
    s.add_development_dependency 'minitest-reporters', '~> 1.5.0'
    s.add_development_dependency 'sqlite3', '~> 1.6.0'
  end

  File.open('anchormodel.gemspec', 'w') do |f|
    f.puts('# DO NOT EDIT')
    f.puts("# This file is auto-generated via: 'rake gemspec'.\n\n")
    f.write(specification.to_ruby.strip)
  end
end

# Create "test" task
require 'minitest/test_task'
Minitest::TestTask.create
