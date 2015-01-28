require 'webrick'
require 'thread'

class Voice::TestHttpServer
  public
    def initialize(port)
      @port = port
      @fixture_root = "#{Rails.root}/spec/fixtures/voice"
      @redirect_map = {}
      @options = {}
    end

    def start
      @started = false
      @lock = Mutex.new
      @cond = ConditionVariable.new
      @server_thread = Thread.new do
        server = WEBrick::HTTPServer.new(
          :Port => @port,
          :Logger => WEBrick::Log.new('/dev/null'),
          :AccessLog => [],
          :StartCallback => proc { set_started })
        server.mount_proc("/") do |request, response|
          handle(request, response)
        end
        Signal.trap(:INT) do
          server.shutdown
        end
        server.start
      end

      wait
    end

    def wait
      @lock.synchronize do
        unless @started
          @cond.wait(@lock)
        end
      end
    end

    def release_wait
      @lock.synchronize do
        @cond.broadcast
      end
    end

    def stop
      release_wait
      Process.kill(:INT, Process.pid)
      @server_thread.join
      @server_thread = nil
    end

    def add_redirect(from, to)
      @redirect_map[from] = to
    end

    def remove_redirect(from)
      @redirect_map.delete(from)
    end

    def add_options(path, opts)
      @options[path] = opts
    end

    def remove_options(path)
      @options.delete(path)
    end

  private
    def set_started
      @lock.synchronize do
        @flag = true
        @cond.broadcast
      end
    end

    def handle(request, response)
      path = "/#{request.path}".gsub(/\/\/+/, "/")
      opts = @options.fetch(path, {})
      path = @redirect_map.fetch(path, path)
      path = "#{@fixture_root}/#{path}".gsub(/\/\/+/, "/")

      raise WEBrick::HTTPStatus::NotFound unless ::File.exist?(path)

      file = ::File.new(path)
      status_code = opts[:status_code]
      last_modified = opts.fetch(:last_modified, ::File.mtime(path))
      last_modified = last_modified.httpdate if last_modified.respond_to?(:httpdate)
      etag = opts.fetch(:etag, make_etag(file))
      wait = opts[:wait].present? ? opts[:wait].to_f : nil

      # sleep wait if wait
      if wait
        begin
          timeout(wait) do
            @lock.synchronize do
              @cond.wait(@lock)
            end
          end
        rescue TimeoutError
          # ignore TimeoutError
        end
      end

      response.status = status_code if status_code.present?
      response.content_type = "text/html; charset=utf-8"
      response["Last-Modified"] = last_modified unless last_modified.nil?
      response["ETag"] = etag if etag !~ /^nil$/i
      response.body = file.read
    end

    def parse_last_modified(last_modified, default)
      if last_modified.blank?
        default
      elsif last_modified =~ /^nil$/i
        nil
      else
        Time.httpdate(last_modified)
      end
    end

    def make_etag(file)
      Digest::SHA1.hexdigest(file.path)
    end
end
