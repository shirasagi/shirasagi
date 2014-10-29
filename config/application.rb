require File.expand_path('../boot', __FILE__)

# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module SS
  mattr_reader(:version) { "0.4.0+" }

  class Application < Rails::Application
    config.autoload_paths << "#{config.root}/lib"
    config.autoload_paths << "#{config.root}/app/validators"

    I18n.enforce_available_locales = true
    config.time_zone = 'Tokyo'
    config.i18n.default_locale = :ja

    Dir["#{config.root}/config/locales/*/*.{rb,yml}"].each do |file|
      config.i18n.load_path << file unless config.i18n.load_path.index(file)
    end
    Dir["#{config.root}/config/routes/*/routes.rb"].sort.each do |file|
      config.paths["config/routes.rb"] << file
    end
    Dir["#{config.root}/config/routes/*/routes_end.rb"].sort.each do |file|
      config.paths["config/routes.rb"] << file
    end
  end
end

def dump(*args)
  SS::Debug.dump(*args) #::File.open("#{Rails.root}/log/dump.log", "a") {|f| f.puts args.inspect }
end
