require 'webrick'

module SS
  module HttpServerSupport
    extend ActiveSupport::Concern

    class Server
      public
        def initialize(doc_root, bind_addr, port)
          @doc_root = doc_root
          @bind_addr = bind_addr
          @port = port
          @options = {}
          @started = false
          @lock = Mutex.new
          @cond = ConditionVariable.new
        end

        attr_reader :doc_root, :bind_addr, :port
        attr_accessor :options

        def start
          @server_thread = Thread.start(self) do |container|
            @server = ::WEBrick::HTTPServer.new(
              BindAddress: @bind_addr,
              Port: @port,
              Logger: WEBrick::Log.new('/dev/null'),
              AccessLog: [],
              StartCallback: proc { set_started })
            @server.mount_proc("/") do |request, response|
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
          handler = @options[:handler]
          if handler.present?
            handler.call(request, response)
            return
          end

          wait_filter(request, response)
          default_handler(request, response)
        end

        def wait_filter(request, response)
          wait = @options[:wait]
          return if wait.blank?

          # sleep wait if wait
          begin
            wait = wait.to_f if wait.respond_to?(:to_f)
            timeout(wait) do
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

          status_code = @options[:status_code]
          content_type = @options[:content_type]
          last_modified = @options.fetch(:last_modified, ::File.mtime(path))
          last_modified = last_modified.httpdate if last_modified.respond_to?(:httpdate)
          etag = @options.fetch(:etag, make_etag(path))

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
          path = @options.fetch(:real_path, path)
          path = "#{@doc_root}/#{path}".gsub(/\/\/+/, "/")
          path
        end

        def make_etag(path)
          Digest::SHA1.hexdigest(path)
        end
    end

    def self.extended(obj)
      doc_root = obj.metadata[:doc_root]
      bind_addr = obj.metadata[:bind_addr] || "127.0.0.1"
      port = obj.metadata[:port] || 20_000 + Random.rand(10_000)

      obj.before(:context) do
        http_server = Server.new(doc_root, bind_addr, port)
        http_server.start
        @http_server = http_server
        Rails.logger.info "http server is listening on #{bind_addr}:#{port}"
      end

      obj.after(:context) do
        http_server = @http_server
        @http_server = nil
        next if http_server.nil?
        http_server.stop
        Rails.logger.info "http server has stopped"
      end
    end

    def http_server
      @http_server
    end
  end
end
