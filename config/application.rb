require File.expand_path('../boot', __FILE__)

# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module SS
  mattr_reader(:version) { "1.7.0" }

  class Application < Rails::Application
    config.autoload_paths << "#{config.root}/lib"
    config.autoload_paths << "#{config.root}/app/validators"
    config.autoload_paths << "#{config.root}/app/helpers/concerns"
    config.autoload_paths << "#{config.root}/app/jobs/concerns"
    config.assets.paths << "#{config.root}/public/assets/css"
    config.assets.paths << "#{config.root}/public/assets/js"
    config.assets.precompile << proc do |path, fn|
      fn =~ /#{Rails.root}\/app/ && %w(.js .css).include?(::File.extname(path)) && path !~ /\/lib\// && path !~ /\/_/
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

    config.paths["config/initializers"] << "#{config.root}/config/after_initializers"

    config.middleware.use Mongoid::QueryCache::Middleware

    attr_reader :current_env

    def call(*args, &block)
      @current_env = args.first
      super
    ensure
      @current_env = nil
      @current_request = nil
    end

    def current_request
      return if @current_env.nil?
      @current_request ||= ActionDispatch::Request.new(@current_env)
    end

    def current_session_id
      return unless @current_env

      session = @current_env[Rack::Session::Abstract::ENV_SESSION_KEY]
      return unless session

      session.id
    end

    def current_request_id
      return unless @current_env
      @current_env['action_dispatch.request_id'] || @env['HTTP_X_REQUEST_ID']
    end
  end

  def self.config
    # lazy loading
    @_ss_config ||= "SS::Config".constantize.setup
  end
end

def dump(*args)
  SS::Debug.dump(*args) #::File.open("#{Rails.root}/log/dump.log", "a") {|f| f.puts args.inspect }
end
