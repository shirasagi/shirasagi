require 'webrick'

module SS
  module HttpServerSupport
    extend ActiveSupport::Concern

    class Server
      DEFAULT_PORT = 4321

      def initialize
        @default_options = {}
        @options = {}
        @started = false
        @lock = Mutex.new
        @cond = ConditionVariable.new
      end

      def default(options = {})
        @default_options.merge!(options)
      end

      def default=(options)
        @default_options = options
      end

      def options(opts = {})
        @options.merge!(opts)
      end

      def options=(opts)
        @options = opts
      end

      def self.define_option_get(name, opts = {})
        key = opts[:key] || name
        key = key.to_sym
        default_value = opts[:default]

        define_method(name) do
          @options.fetch(key) do
            @default_options.fetch(key) do
              default_value.is_a?(Proc) ? default_value.call : default_value
            end
          end
        end
      end

      # this property does:
      #
      #   @options.fetch(:addr, @default_options.fetch(:addr, "127.0.0.1"))
      define_option_get :addr, default: "127.0.0.1"

      # this property does:
      #
      #   @options.fetch(:port, @default_options.fetch(:port, DEFAULT_PORT))
      define_option_get :port, default: DEFAULT_PORT

      # this property does:
      #
      #   @options.fetch(:mount_dir, @default_options.fetch(:mount_dir, "/"))
      define_option_get :mount_dir, default: "/"

      # this property does:
      #
      #   @options.fetch(:doc_root, @default_options.fetch(:doc_root, Rails.root.to_s))
      define_option_get :doc_root, default: -> { Rails.root.to_s }

      # this property does:
      #
      #   @options.fetch(:handler, @default_options.fetch(:handler, nil))
      define_option_get :handler

      # this property does:
      #
      #   @options.fetch(:wait, @default_options.fetch(:wait, nil))
      define_option_get :wait_sec, key: :wait

      # this property does:
      #
      #   @options.fetch(:status_code, @default_options.fetch(:status_code, nil))
      define_option_get :status_code

      # this property does:
      #
      #   @options.fetch(:content_type, @default_options.fetch(:content_type, nil))
      define_option_get :content_type

      # this property does:
      #
      #   @options.fetch(:last_modified, @default_options.fetch(:last_modified, nil))
      define_option_get :last_modified

      # this property does:
      #
      #   @options.fetch(:etag, @default_options.fetch(:etag, nil))
      define_option_get :etag

      # this property does:
      #
      #   @options.fetch(:real_path, @default_options.fetch(:real_path, nil))
      define_option_get :real_path

      # this property does:
      #
      #   @options.fetch(:logger, @default_options.fetch(:logger, Rails.logger))
      define_option_get :logger, default: -> { Rails.logger }

      def started?
        @started
      end

      def stopped?
        !started?
      end

      def start
        @server_thread = Thread.start(self) do |container|
          @server = ::WEBrick::HTTPServer.new(
            BindAddress: addr,
            Port: port,
            Logger: logger,
            AccessLog: [],
            StartCallback: proc { set_started })
          @server.mount_proc(mount_dir) do |request, response|
            handle(request, response)
          end
          Signal.trap(:INT) do
            @server.shutdown
          end
          @server.start
          container.instance_variable_set(:@server, @server)
        end

        wait
      end

      def release_wait
        @lock.synchronize do
          @cond.broadcast
        end
      end

      def stop
        release_wait
        @server.shutdown
        @server_thread.join
        @started = false
        @server_thread = nil
        @server = nil
      end

      private
        def set_started
          @lock.synchronize do
            @started = true
            @cond.broadcast
          end
        end

        def wait
          @lock.synchronize do
            unless @started
              @cond.wait(@lock)
            end
          end
        end

        def handle(request, response)
          handler = self.handler
          if handler.present?
            handler.call(request, response)
            return
          end

          wait_filter(request, response)
          default_handler(request, response)
        end

        def wait_filter(request, response)
          wait_sec = self.wait_sec
          return if wait_sec.blank?

          begin
            wait_sec = wait_sec.to_f if wait_sec.respond_to?(:to_f)
            timeout(wait_sec) do
              @lock.synchronize do
                @cond.wait(@lock)
              end
            end
          rescue TimeoutError
            # ignore TimeoutError
          end
        end

        def default_handler(request, response)
          path = map_path(request, response)
          raise WEBrick::HTTPStatus::NotFound unless ::File.exist?(path)

          status_code = self.status_code
          content_type = self.content_type
          last_modified = self.last_modified || ::File.mtime(path)
          last_modified = last_modified.httpdate if last_modified.respond_to?(:httpdate)
          etag = self.etag || make_etag(path)

          ::File.open(path, "rb:ASCII-8BIT") do |file|
            response.status = status_code if status_code.present?
            response.content_type = content_type if content_type.present?
            response["Last-Modified"] = last_modified if last_modified.present?
            response["ETag"] = etag if etag.present?
            response.body = file.read
          end
        end

        def map_path(request, response)
          path = "/#{request.path}".gsub(/\/\/+/, "/")
          path = self.real_path || path
          path = "#{doc_root}/#{path}".gsub(/\/\/+/, "/")
          path
        end

        def make_etag(path)
          Digest::SHA1.hexdigest(path)
        end
    end

    def self.extended(obj)
      obj.metadata[:_http] = Server.new

      obj.before(:example) do
        http_server = obj.metadata[:_http]
        if http_server && http_server.stopped?
          http_server.start
          Rails.logger.info "http server is listening on #{http_server.addr}:#{http_server.port}"
        end
      end

      obj.after(:example) do
        http_server = obj.metadata[:_http]
        if http_server
          http_server.release_wait
          http_server.options.clear
        end
      end

      obj.after(:context) do
        http_server = obj.metadata[:_http]
        obj.metadata[:_http] = nil
        next if http_server.nil?
        http_server.stop
        Rails.logger.info "http server has stopped"
      end

      obj.class_eval do
        # this class method is called from outside of examples
        define_singleton_method(:http) do
          obj.metadata[:_http]
        end

        # this instance method is called from inside of a example
        define_method(:http) do
          obj.metadata[:_http]
        end
      end
    end
  end
end
