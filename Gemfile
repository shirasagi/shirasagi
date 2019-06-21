source 'https://rubygems.org'

gem 'rails', '~> 5.2.0'
gem 'sassc-rails'
gem 'uglifier'
gem 'coffee-rails'
gem 'therubyracer', platforms: :ruby
gem 'jbuilder'
gem 'sdoc', group: :doc

# Server
gem 'unicorn'
gem 'unicorn-worker-killer'

# Database
gem 'mongoid', git: 'https://github.com/mongodb/mongoid.git' #'~> 7.1.0'
gem 'mongo_session_store', git: 'https://github.com/mongoid/mongo_session_store.git'
gem 'mongoid-rspec', git: 'https://github.com/mongoid/mongoid-rspec.git'
gem 'mongoid-grid_fs', git: 'https://github.com/mongoid/mongoid-grid_fs.git'

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

# Additional
gem 'browser'
gem 'clam_scan'
gem 'diff-lcs'
gem 'diffy'
gem 'dynamic_form'
gem 'fast_blank'
gem 'fullcalendar.io-rails', '~> 2.6.0'
gem 'holiday_japan'
gem 'icalendar'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'kramdown'
gem 'mail-iso-2022-jp'
gem 'net-ldap'
gem 'non-stupid-digest-assets'
gem 'oj'
gem 'open_uri_redirections'
gem 'rails_autolink'
gem 'rmagick'
gem 'romaji'
gem 'simple_captcha2', require: 'simple_captcha'
gem 'ungarbled'
gem 'rubyzip'
gem 'thinreports'
gem 'bootsnap', require: false
gem 'addressable', require: 'addressable/uri'
gem 'roo'
#gem 'roo-xls', git: "https://github.com/roo-rb/roo-xls.git"
gem 'liquid'

# OAuth
gem 'oauth2', git: 'https://github.com/oauth-xx/oauth2.git' #'~> 1.5.0'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-google-oauth2', git: 'https://github.com/zquestz/omniauth-google-oauth2.git'
gem 'omniauth-twitter'
gem 'omniauth-yahoojp'

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

group :development, :test do
  gem 'capybara'
  gem 'coveralls', require: false
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'fuubar'
  gem 'guard'
  gem 'guard-rspec', '~> 4.3.1'
  gem 'guard-rubocop'
  gem 'selenium-webdriver', require: false
  gem 'webdrivers'
  gem 'pry-rails'
  gem 'pry-doc'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
  gem 'rspec'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'rails-controller-testing'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'spring', '~> 2.0.2'
  gem 'timecop'
end

group :development do
  gem 'brakeman', require: false
  gem 'guard-brakeman', require: false
  gem 'yard', require: false
  gem 'terminal-notifier-guard', require: false
end

group :test do
  gem 'webmock'
  gem 'docker-api'
end
