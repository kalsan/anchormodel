# DO NOT EDIT
# This file is auto-generated via: 'rake gemspec'.

# -*- encoding: utf-8 -*-
# stub: anchormodel 0.2.5.edge ruby lib

Gem::Specification.new do |s|
  s.name = "anchormodel".freeze
  s.version = "0.2.5.edge".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sandro Kalbermatter".freeze]
  s.date = "2024-11-06"
  s.files = [".gitignore".freeze, ".ruby-version".freeze, ".yardopts".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "Gemfile.lock".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "VERSION".freeze, "anchormodel.gemspec".freeze, "bin/rails".freeze, "doc/Anchormodel.html".freeze, "doc/Anchormodel/ActiveModelTypeValue.html".freeze, "doc/Anchormodel/ActiveModelTypeValueMulti.html".freeze, "doc/Anchormodel/ActiveModelTypeValueSingle.html".freeze, "doc/Anchormodel/Attribute.html".freeze, "doc/Anchormodel/ModelMixin.html".freeze, "doc/Anchormodel/SimpleFormInputs.html".freeze, "doc/Anchormodel/SimpleFormInputs/Helpers.html".freeze, "doc/Anchormodel/SimpleFormInputs/Helpers/AnchormodelInputsCommon.html".freeze, "doc/Anchormodel/Util.html".freeze, "doc/Anchormodel/Version.html".freeze, "doc/AnchormodelCheckBoxesInput.html".freeze, "doc/AnchormodelGenerator.html".freeze, "doc/AnchormodelInput.html".freeze, "doc/AnchormodelRadioButtonsInput.html".freeze, "doc/_index.html".freeze, "doc/class_list.html".freeze, "doc/css/common.css".freeze, "doc/css/full_list.css".freeze, "doc/css/style.css".freeze, "doc/file.README.html".freeze, "doc/file_list.html".freeze, "doc/frames.html".freeze, "doc/index.html".freeze, "doc/js/app.js".freeze, "doc/js/full_list.js".freeze, "doc/js/jquery.js".freeze, "doc/method_list.html".freeze, "doc/top-level-namespace.html".freeze, "lib/anchormodel.rb".freeze, "lib/anchormodel/active_model_type_value_multi.rb".freeze, "lib/anchormodel/active_model_type_value_single.rb".freeze, "lib/anchormodel/attribute.rb".freeze, "lib/anchormodel/model_mixin.rb".freeze, "lib/anchormodel/simple_form_inputs/anchormodel_check_boxes_input.rb".freeze, "lib/anchormodel/simple_form_inputs/anchormodel_input.rb".freeze, "lib/anchormodel/simple_form_inputs/anchormodel_radio_buttons_input.rb".freeze, "lib/anchormodel/simple_form_inputs/helpers/anchormodel_inputs_common.rb".freeze, "lib/anchormodel/util.rb".freeze, "lib/anchormodel/version.rb".freeze, "lib/generators/anchormodel/USAGE".freeze, "lib/generators/anchormodel/anchormodel_generator.rb".freeze, "lib/generators/anchormodel/templates/anchormodel.rb.erb".freeze, "logo.svg".freeze, "test/active_record_model/user_test.rb".freeze, "test/dummy/.gitignore".freeze, "test/dummy/Rakefile".freeze, "test/dummy/app/anchormodels/animal.rb".freeze, "test/dummy/app/anchormodels/locale.rb".freeze, "test/dummy/app/anchormodels/role.rb".freeze, "test/dummy/app/helpers/application_helper.rb".freeze, "test/dummy/app/models/application_record.rb".freeze, "test/dummy/app/models/concerns/.keep".freeze, "test/dummy/app/models/user.rb".freeze, "test/dummy/bin/rails".freeze, "test/dummy/bin/rake".freeze, "test/dummy/bin/setup".freeze, "test/dummy/config.ru".freeze, "test/dummy/config/application.rb".freeze, "test/dummy/config/boot.rb".freeze, "test/dummy/config/credentials.yml.enc".freeze, "test/dummy/config/database.yml".freeze, "test/dummy/config/environment.rb".freeze, "test/dummy/config/environments/test.rb".freeze, "test/dummy/config/initializers/content_security_policy.rb".freeze, "test/dummy/config/initializers/filter_parameter_logging.rb".freeze, "test/dummy/config/initializers/inflections.rb".freeze, "test/dummy/config/initializers/permissions_policy.rb".freeze, "test/dummy/config/locales/en.yml".freeze, "test/dummy/config/puma.rb".freeze, "test/dummy/config/routes.rb".freeze, "test/dummy/db/migrate/20230107173151_create_users.rb".freeze, "test/dummy/db/migrate/20240425182000_add_animals_to_users.rb".freeze, "test/dummy/db/schema.rb".freeze, "test/dummy/db/seeds.rb".freeze, "test/dummy/lib/tasks/.keep".freeze, "test/dummy/log/.keep".freeze, "test/dummy/tmp/.keep".freeze, "test/dummy/tmp/pids/.keep".freeze, "test/test_helper.rb".freeze]
  s.homepage = "https://github.com/kalsan/anchormodel".freeze
  s.licenses = ["LGPL-3.0-or-later".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.5.22".freeze
  s.summary = "Bringing object-oriented programming to Rails enums".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, [">= 7.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0.6".freeze])
  s.add_development_dependency(%q<pry>.freeze, ["~> 0.14.1".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.43.0".freeze])
  s.add_development_dependency(%q<rubocop-rails>.freeze, ["~> 2.17.4".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9.28".freeze])
  s.add_development_dependency(%q<yard-activesupport-concern>.freeze, ["~> 0.0.1".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.17.0".freeze])
  s.add_development_dependency(%q<minitest-reporters>.freeze, ["~> 1.5.0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.6.0".freeze])
end