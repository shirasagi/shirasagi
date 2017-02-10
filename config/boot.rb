require 'yaml'
file = File.expand_path('./environment.yml', __dir__)
renv = File::exist?(file) ? YAML.load_file(file)['RAILS_ENV'] : 'production'
ENV['RAILS_ENV'] ||= renv

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
