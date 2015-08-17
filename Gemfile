source "https://rubygems.org"

gem "rails", "4.2.3"
gem 'sass-rails', '~> 5.0'
gem "uglifier", ">= 1.3.0"
gem 'coffee-rails', '~> 4.1.0'
gem "therubyracer", "~> 0.10.2", platforms: :ruby
gem "jquery-rails"
gem "turbolinks"
gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0', group: :doc

# gem 'bcrypt', '~> 3.1.7'
gem "unicorn"
# gem 'capistrano-rails', group: :development
# gem "debugger", group: [:development, :test]

gem "mongoid", "~> 4.0.0"
gem "mongoid-rspec"
gem "mongo_mapper"
gem "bson_ext"
#gem "cells"
gem "dynamic_form"
gem "zipruby"
gem "jquery-turbolinks"
gem "jquery-cookie-rails"
gem 'jquery-form-rails'
gem "redcarpet"
gem "compass-rails"
gem "kaminari"
gem "non-stupid-digest-assets"
gem "mongoid-grid_fs"
#gem "carrierwave"
#gem "carrierwave-mongoid", require: "carrierwave/mongoid"
gem "rmagick"
gem "holiday_japan"
gem "mail-iso-2022-jp"
gem 'simple_captcha2', require: 'simple_captcha'
gem "rails_autolink"
gem "browser"
#gem 'sass-rails-source-maps'
#gem 'coffee-rails-source-maps'
gem "net-ldap"
gem "diffy"
gem "ungarbled"
gem "fullcalendar-rails", "2.3.1.0"
gem "momentjs-rails", "2.10.2"
gem 'bxslider-rails'
gem 'clam_scan'

# OAuth
gem 'omniauth'
gem 'omniauth-twitter'
gem 'omniauth-facebook'
gem 'omniauth-yahoojp'
gem 'omniauth-google-oauth2'
gem 'omniauth-github'

#gem "rails-dev-boost", git: "git://github.com/thedarkone/rails-dev-boost.git", group: :development

group :development, :test do
  gem 'spring', '~> 1.1.3'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rspec-its'
  gem 'rspec-collection_matchers'
  gem 'capybara'
  gem 'factory_girl_rails'
  gem 'coveralls', require: false
  gem 'rubocop', require: false
  gem 'poltergeist', require: false
  gem 'guard'
  gem 'guard-rubocop', '~> 1.1.0'
  gem 'guard-rspec', '~> 4.3.1'
  gem 'fuubar'
  gem 'timecop'
  gem 'pry-rails'
  gem 'pry-doc'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'

  # DatabaseCleaner
  #
  # ref.
  #   https://github.com/DatabaseCleaner/database_cleaner
  #   http://stackoverflow.com/questions/6583618/clean-out-or-reset-test-database-with-rspec-and-mongoid-on-rails-3
  #
  # Version 1.4.0 is latest now, but that version contaions an error.
  #
  # Error message:
  #   DatabaseCleaner::UnknownStrategySpecified:
  #          The 'truncation' strategy does not exist for the mongoid ORM!  Available strategies: truncation
  #
  # ref.
  #   https://github.com/DatabaseCleaner/database_cleaner/issues/322
  #   https://github.com/DatabaseCleaner/database_cleaner/issues/299
  gem 'database_cleaner', '1.3.0'
end

group :development do
  gem 'brakeman', require: false
  gem 'guard-brakeman', require: false
  gem 'yard', require: false
  #gem 'rack-mini-profiler'
end
