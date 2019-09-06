# encoding: UTF-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'vinsol_spree_themes/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'vinsol_spree_themes'
  s.version     = VinsolSpreeThemes.version
  s.summary     = 'This extension creates a flexible system where admin can upload, modify the themes and publish it to spree store.'
  s.description = 'This extension provides an interface for the admin to upload new themes, publish it to the spree store, modify the theme layout accordingly and later download it.'
  s.required_ruby_version = '>= 2.2.7'

  s.author    = ['Paresh Gupta', 'Nimish Mehta']
  s.email     = 'info@vinsol.com'
  s.homepage  = 'http://vinsol.com'
  s.license = 'BSD-3-Clause'

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '>= 3.2.0'
  s.add_dependency 'rubyzip', '~> 1.2.1'
  s.add_dependency 'state_machine', '~> 1.2.0'
  s.add_dependency 'sprockets-helpers', '~> 1.2.1'

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'capybara-screenshot'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'appraisal'
end
