source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'rails', '~> 7.1.0'
gem 'sprockets'
gem 'jsbundling-rails'
gem 'sprockets-rails' # Rails 7.1 以降では明示的な組み込みが必要
gem 'dartsass-sprockets'
# gem 'sass' # app/models/fs/grid_fs/compass_importer.rb で require しているので必要
gem 'uglifier'
gem 'coffee-rails'
gem 'jbuilder'
gem 'sdoc', group: :doc
# rdoc 6.4 以降にアップデートすると依存関係に 'psych' と 'stringio' が組み込まれる。
# 'psych' と 'stringio' が組み込まれると 'bin/rails' コマンドや 'bin/rake' コマンドが動作しなくなり、
# 'bundle exec rails' や 'bundle exec rake' を使用しなければならなくなるので、バージョンを固定する。
gem 'rdoc', '~> 6.3.0', group: :doc #

# Server
gem 'unicorn'
gem 'unicorn-worker-killer'

# Database
gem 'mongoid'
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

# Additional (alphabetical order)
gem 'addressable', require: 'addressable/uri'
gem 'bootsnap', require: false
gem 'browser'
gem 'clam_scan'
gem 'diff-lcs'
gem 'diffy'
gem 'dotenv-rails'
gem 'fast_blank'
gem 'fastimage'
gem 'geocoder'
gem 'google-api-client'
gem 'holiday_japan'
gem 'http_accept_language'
gem 'icalendar'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'kramdown'
gem 'kramdown-parser-gfm'
gem 'liquid'
gem 'mail' # must load 'mail' before loading 'mail-iso-2022-jp'
gem 'mail-iso-2022-jp'
gem 'marcel'
gem 'mini_magick'
gem 'mongoid-geospatial'
gem 'net-ldap'
gem 'net-imap'
gem 'net-pop'
gem 'net-smtp'
gem 'non-stupid-digest-assets'
gem 'oj'
gem 'rails_autolink'
gem 'retriable'
gem 'rexml'
gem 'romaji'
gem 'roo'
#gem 'roo-xls', git: "https://github.com/roo-rb/roo-xls.git"
gem 'rotp'
gem 'rqrcode'
gem 'rss'
gem 'rubyzip', '~> 2.3.0'
gem 'shortuuid'
gem 'thinreports'
gem 'ungarbled'
gem 'view_component'
gem 'wareki'

# OAuth
gem 'oauth2'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
gem 'omniauth-twitter'
gem 'omniauth-twitter2'
gem 'omniauth-yahoojp'
gem 'omniauth-line'
gem 'omniauth-rails_csrf_protection'

# SNS
gem 'x'

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
gem 'elasticsearch', '~> 7'

# line
gem 'line-bot-api'

# kintone
gem 'kintone', git: "https://github.com/jue58/kintone.git"

group :development, :test do
  gem 'brakeman', require: false
  gem 'capybara', require: false
  gem 'debug', require: false
  gem 'factory_bot_rails', require: false
  gem 'fuubar', require: false
  gem 'guard', require: false
  gem 'guard-rspec', '~> 4.3.1', require: false
  gem 'guard-rubocop', require: false
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
  gem 'rubocop', '~> 1.66', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rails', '~> 2.26', require: false
  gem 'selenium-webdriver', require: false
  gem 'simplecov', require: false
  gem 'simplecov-csv', require: false
  gem 'simplecov-html', require: false
  gem 'simplecov-lcov', require: false
  gem 'test-queue', require: false
  gem 'timecop', require: false
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
