require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SS
  mattr_reader(:version) { "1.13.2" }

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0

    config.autoload_paths << "#{config.root}/lib"
    config.autoload_paths << "#{config.root}/app/validators"
    config.autoload_paths << "#{config.root}/app/helpers/concerns"
    config.autoload_paths << "#{config.root}/app/jobs/concerns"

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
    Dir["#{config.root}/config/routes/**/routes_end.rb"].sort.reverse_each do |file|
      config.paths["config/routes.rb"] << file
    end
    config.paths["config/routes.rb"] << "#{config.root}/config/routes_end.rb"

    config.paths["config/initializers"] << "#{config.root}/config/after_initializers"

    config.middleware.use Mongoid::QueryCache::Middleware

    cattr_accessor(:private_root, instance_accessor: false) { "#{Rails.root}/private" }

    def call(*args, &block)
      save_current_env = Thread.current["ss.env"]
      save_current_request = Thread.current["ss.request"]
      Thread.current["ss.env"] = args.first
      Thread.current["ss.request"] = nil
      super
    ensure
      Thread.current["ss.env"] = save_current_env
      Thread.current["ss.request"] = save_current_request
    end

    def current_env
      Thread.current["ss.env"]
    end

    def current_request
      return if current_env.nil?
      Thread.current["ss.request"] ||= ActionDispatch::Request.new(current_env)
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

  def self.config
    # lazy loading
    @_ss_config ||= "SS::Config".constantize.setup
  end
end

def dump(*args)
  SS::Debug.dump(*args) #::File.open("#{Rails.root}/log/dump.log", "a") {|f| f.puts args.inspect }
end
