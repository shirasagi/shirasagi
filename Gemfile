source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'rails', '~> 6.1.0'
gem 'sprockets', '< 4.0'
gem 'sass'
gem 'sassc-rails'
gem 'uglifier'
gem 'coffee-rails'
gem 'mini_racer'
gem 'jbuilder'
gem 'sdoc', group: :doc

# Server
gem 'unicorn'
gem 'unicorn-worker-killer'

# Database
gem 'mongoid', github: 'shirasagi/mongoid', branch: '7.3-stable-MONGOID-5183'
gem 'mongo_session_store'
gem 'mongoid-grid_fs'

# Assets
gem 'autosize-rails'
gem 'bxslider-rails'
gem 'js_cookie_rails'
gem 'jquery-form-rails'
gem 'jquery-minicolors-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'marked-rails'
gem 'momentjs-rails'

# Additional (alphabetical order)
gem 'addressable', require: 'addressable/uri'
gem 'bootsnap', require: false
gem 'browser'
gem 'clam_scan'
gem 'diff-lcs'
gem 'diffy'
gem 'fast_blank'
gem 'fastimage'
gem 'fullcalendar.io-rails', '~> 2.6.0'
gem 'geocoder'
gem 'google-cloud-translate', '2.0.0'
gem 'holiday_japan'
gem 'http_accept_language'
gem 'icalendar'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'kramdown'
gem 'kramdown-parser-gfm'
gem 'liquid'
gem 'mail-iso-2022-jp'
gem 'marcel'
gem 'mini_magick'
gem 'net-ldap'
gem 'non-stupid-digest-assets'
gem 'oj'
gem 'rails_autolink'
gem 'retriable'
gem 'rexml'
gem 'romaji'
gem 'roo'
#gem 'roo-xls', git: "https://github.com/roo-rb/roo-xls.git"
gem 'rss'
gem 'rubyzip', '~> 2.3.0'
gem 'thinreports'
gem 'ungarbled'
gem 'mongoid-geospatial'

# OAuth
gem 'oauth2'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
gem 'omniauth-twitter'
gem 'omniauth-yahoojp'
gem 'omniauth-line'
gem 'omniauth-rails_csrf_protection'

# SNS
gem 'twitter'

# SAML
gem 'ruby-saml'

# JWT/JWS
gem 'jwt'
gem 'json-jwt'

# SPARQL/RDF
gem 'levenshtein'
gem 'rdf-rdfxml'
gem 'rdf-turtle'
gem 'sparql'
gem 'sparql-client'
gem 'unf'

# elasticsearch
gem 'faraday'
gem 'elasticsearch'

# line
gem 'line-bot-api'

group :development, :test do
  gem 'brakeman', require: false
  gem 'dotenv-rails'
  gem 'capybara', require: false
  gem 'debase', require: false
  gem 'factory_bot_rails', require: false
  gem 'fuubar', require: false
  gem 'guard', require: false
  gem 'guard-rspec', '~> 4.3.1', require: false
  gem 'guard-rubocop', require: false
  gem 'guard-scss_lint', require: false
  gem 'mongoid-rspec', require: false
  gem 'pry-byebug', require: false
  gem 'pry-doc', require: false
  gem 'pry-rails', require: false
  gem 'pry-stack_explorer', require: false
  gem 'puma', require: false
  gem 'rails-controller-testing', require: false
  gem 'rspec', require: false
  gem 'rspec-collection_matchers', require: false
  gem 'rspec-its', require: false
  gem 'rspec-rails', require: false
  gem 'rubocop', '1.18.4', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rails', '2.11.3', require: false
  gem 'ruby-debug-ide', require: false
  gem 'scss_lint', require: false
  gem 'selenium-webdriver', require: false
  gem 'simplecov', require: false
  gem 'simplecov-csv', require: false
  gem 'simplecov-html', require: false
  gem 'simplecov-lcov', require: false
  gem 'spring', '~> 2.0.2', require: false
  gem 'test-queue', require: false
  gem 'timecop', require: false
  gem 'webdrivers', require: false
end

group :development do
  gem 'guard-brakeman', require: false
  gem 'terminal-notifier-guard', require: false
  gem 'yard', require: false
end

group :test do
  gem 'docker-api'
  gem 'rspec-retry', require: false
  gem 'webmock'
end
