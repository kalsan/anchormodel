# DO NOT EDIT
# This file is auto-generated via: 'rake gemspec'.

# -*- encoding: utf-8 -*-
# stub: anchormodel 0.0.1.edge ruby lib

Gem::Specification.new do |s|
  s.name = "anchormodel".freeze
  s.version = "0.0.1.edge"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sandro Kalbermatter".freeze]
  s.date = "2022-12-17"
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.2.33".freeze
  s.summary = "Bringing object-oriented programming to Rails enums".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rails>.freeze, [">= 7.0"])
  else
    s.add_dependency(%q<rails>.freeze, [">= 7.0"])
  end
end