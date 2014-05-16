# Set up default environment.
require "yaml"
file = File.expand_path('../../config/environment.yml', __FILE__)
env = File::exist?(file) ? YAML.load_file(file) : {}
ENV['RAILS_ENV'] ||= env["RAILS_ENV"]

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
