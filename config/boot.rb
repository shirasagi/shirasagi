# Set up default environment.
require 'yaml'

ENV['RAILS_ENV'] ||= begin
  file = ::File.expand_path('../config/environment.yml', __dir__)
  if ::File::exist?(file)
    environment = YAML.safe_load_file(file, aliases: true, permitted_classes: [Symbol])
    renv = environment['RAILS_ENV']
  end
  renv || 'production'
end

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
