require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

require_relative "../app/models/ss"
require_relative "../app/models/ss/config"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SS
  mattr_reader(:version) { "1.19.1" }

  class Current < ActiveSupport::CurrentAttributes
    attribute :env, :request
    attribute :site, :user, :user_group, :organization, :token

    THREAD_LOCAL_VARIABLES = %i[env request site user user_group organization token].freeze

    def self.with_scope
      save_context = instance.attributes.dup
      yield
    ensure
      THREAD_LOCAL_VARIABLES.each do |variable_name|
        instance.attributes[variable_name] = save_context[variable_name]
      end
    end
  end

  class CurrentScoping
    def initialize(app)
      @app = app
    end

    def call(env)
      Current.with_scope do
        Current.env = env
        Current.request = nil

        @app.call(env)
      end
    end
  end

  def self.config
    @_ss_config ||= SS::Config.setup
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets fixtures generators guard migrations))

    config.action_dispatch.rescue_responses["SS::ForbiddenError"] = :forbidden # 403
    config.action_dispatch.rescue_responses["SS::NotFoundError"] = :not_found # 404

    # see: https://til.toshimaru.net/2023-03-30
    config.action_controller.raise_on_open_redirects = false

    config.middleware.delete ActionDispatch::HostAuthorization

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.autoload_paths << "#{config.root}/lib"
    config.autoload_paths << "#{config.root}/app/validators"
    config.autoload_paths << "#{config.root}/app/helpers/concerns"
    config.autoload_paths << "#{config.root}/app/jobs/concerns"

    # Don't generate system test files.
    config.generators.system_tests = nil

    I18n.enforce_available_locales = true
    config.i18n.default_locale = :ja
    if SS.config.env.available_locales.present?
      I18n.available_locales = SS.config.env.available_locales.map(&:to_sym)
      config.i18n.fallbacks = I18n.available_locales.index_with do |lang|
        if lang == config.i18n.default_locale
          I18n.available_locales - [ config.i18n.default_locale ]
        else
          I18n.available_locales - [ lang ]
        end
      end
    else
      config.i18n.fallbacks = [ :en ]
    end
    config.time_zone = 'Tokyo'

    Dir["#{config.root}/config/locales/**/*.{rb,yml}"].each do |file|
      config.i18n.load_path << file unless config.i18n.load_path.index(file)
    end
    Dir["#{config.root}/config/oem/locales/**/*.{rb,yml}"].each do |file|
      config.i18n.load_path << file unless config.i18n.load_path.index(file)
    end
    Dir["#{config.root}/config/routes/**/routes.rb"].sort.each do |file|
      config.paths["config/routes.rb"] << file
    end
    Dir["#{config.root}/config/routes/**/routes_end.rb"].sort.reverse_each do |file|
      config.paths["config/routes.rb"] << file
    end
    config.paths["config/routes.rb"] << "#{config.root}/config/routes_end.rb"

    config.paths["config/initializers"] << "#{config.root}/config/after_initializers"

    config.middleware.use Mongoid::QueryCache::Middleware
    # middelware "ActionDispatch::Executor" で ActiveSupport::CurrentAttributes は reset される。
    # そこで、middelware "ActionDispatch::Executor" の後で Current.env をセットする必要がある
    config.middleware.use CurrentScoping

    cattr_accessor(:private_root, instance_accessor: false) { "#{Rails.root}/private" }

    def call(*args, &block)
      I18n.with_locale(I18n.locale) do
        Time.use_zone(Time.zone) do
          super
        end
      end
    end

    def current_env
      Current.env
    end

    def current_request
      return if current_env.nil?
      Current.request ||= ActionDispatch::Request.new(current_env)
    end

    def current_session_id
      return unless current_env

      session = current_env[Rack::RACK_SESSION]
      return unless session

      session.id
    end

    def current_request_id
      if current_request
        current_request.request_id
      else
        nil
      end
    end

    def current_controller
      return if current_request.nil?
      current_request.params[:controller]
    end

    def current_path_info
      return if current_env.nil?
      current_env["PATH_INFO"]
    end

    def hostname
      @hostname ||= begin
        hostname! rescue nil
      end
    end

    def hostname!
      require "socket"
      Socket.gethostname
    end

    def ip_address
      @ip_address ||= begin
        ip_address! rescue nil
      end
    end

    def ip_address!
      require "socket"

      udp = UDPSocket.new
      # クラスBの先頭アドレス,echoポート 実際にはパケットは送信されない。
      udp.connect("128.0.0.0", 7)
      address = Socket.unpack_sockaddr_in(udp.getsockname)[1]
      address
    ensure
      udp.close rescue nil
    end
  end

  def self.current_site
    Current.site
  end

  def self.current_site=(site)
    Current.site = site
  end

  def self.current_user
    Current.user
  end

  def self.current_user=(user)
    Current.user = user
  end

  def self.current_user_group
    Current.user_group
  end

  def self.current_user_group=(group)
    Current.user_group = group
  end

  def self.current_organization
    Current.organization
  end

  def self.current_organization=(group)
    Current.organization = group
  end

  def self.current_token
    Current.token
  end

  def self.current_token=(token)
    Current.token = token
  end
end

def dump(*args)
  SS::Debug.dump(*args) #::File.open("#{Rails.root}/log/dump.log", "a") {|f| f.puts args.inspect }
end
