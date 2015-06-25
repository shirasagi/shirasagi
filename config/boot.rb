# Set up default environment.
require 'yaml'
file = File.expand_path('../../config/environment.yml', __FILE__)
renv = File::exist?(file) ? YAML.load_file(file)['RAILS_ENV'] : 'production'
ENV['RAILS_ENV'] ||= renv

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
