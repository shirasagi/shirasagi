require File.expand_path('../boot', __FILE__)

# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module SS
  mattr_reader(:version) { "1.3.0" }

  class Application < Rails::Application
    config.autoload_paths << "#{config.root}/lib"
    config.autoload_paths << "#{config.root}/app/validators"
    config.autoload_paths << "#{config.root}/app/jobs/concerns"

    config.assets.paths << "#{config.root}/vendor/assets/packages"
    config.assets.paths << "#{config.root}/public/assets/css"
    config.assets.paths << "#{config.root}/public/assets/js"
    config.assets.precompile << proc do |path, fn|
      fn =~ /app\/assets/ && %w(.js .css).include?(::File.extname(path)) && path !~ /\/lib\// && path !~ /\/_/
    end

    I18n.enforce_available_locales = true
    config.time_zone = 'Tokyo'
    config.i18n.default_locale = :ja
    config.i18n.fallbacks = [ :en ]

    Dir["#{config.root}/config/locales/**/*.{rb,yml}"].each do |file|
      config.i18n.load_path << file unless config.i18n.load_path.index(file)
    end
    Dir["#{config.root}/config/oem/locales/**/*.{rb,yml}"].each do |file|
      config.i18n.load_path << file unless config.i18n.load_path.index(file)
    end
    Dir["#{config.root}/config/routes/**/routes.rb"].sort.each do |file|
      config.paths["config/routes.rb"] << file
    end
    Dir["#{config.root}/config/routes/*/routes_end.rb"].sort.each do |file|
      config.paths["config/routes.rb"] << file
    end

    config.middleware.use "Mongoid::QueryCache::Middleware"
  end

  def self.config
    # lazy loading
    @_ss_config ||= "SS::Config".constantize
  end
end

def dump(*args)
  SS::Debug.dump(*args) #::File.open("#{Rails.root}/log/dump.log", "a") {|f| f.puts args.inspect }
end
