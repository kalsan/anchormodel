# DO NOT EDIT
# This file is auto-generated via: 'rake gemspec'.

# -*- encoding: utf-8 -*-
# stub: anchormodel 0.0.3.edge ruby lib

Gem::Specification.new do |s|
  s.name = "anchormodel".freeze
  s.version = "0.0.3.edge"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sandro Kalbermatter".freeze]
  s.date = "2023-01-04"
  s.files = [".gitignore".freeze, ".ruby-version".freeze, ".yardopts".freeze, "CHANGELOG.md".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "anchormodel.gemspec".freeze, "doc/Anchormodel.html".freeze, "doc/Anchormodel/ActiveModelTypeValue.html".freeze, "doc/Anchormodel/Attribute.html".freeze, "doc/Anchormodel/ModelMixin.html".freeze, "doc/Anchormodel/Version.html".freeze, "doc/_index.html".freeze, "doc/class_list.html".freeze, "doc/css/common.css".freeze, "doc/css/full_list.css".freeze, "doc/css/style.css".freeze, "doc/file.README.html".freeze, "doc/file_list.html".freeze, "doc/frames.html".freeze, "doc/index.html".freeze, "doc/js/app.js".freeze, "doc/js/full_list.js".freeze, "doc/js/jquery.js".freeze, "doc/method_list.html".freeze, "doc/top-level-namespace.html".freeze, "lib/anchormodel.rb".freeze, "lib/anchormodel/active_model_type_value.rb".freeze, "lib/anchormodel/attribute.rb".freeze, "lib/anchormodel/model_mixin.rb".freeze, "lib/anchormodel/version.rb".freeze]
  s.homepage = "https://github.com/kalsan/anchormodel".freeze
  s.licenses = ["LGPL-3.0-or-later".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.3.26".freeze
  s.summary = "Bringing object-oriented programming to Rails enums".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rails>.freeze, ["~> 7.0"])
    s.add_development_dependency(%q<yard>.freeze, ["~> 0.9.28"])
    s.add_development_dependency(%q<yard-activesupport-concern>.freeze, ["~> 0.0.1"])
  else
    s.add_dependency(%q<rails>.freeze, ["~> 7.0"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9.28"])
    s.add_dependency(%q<yard-activesupport-concern>.freeze, ["~> 0.0.1"])
  end
end