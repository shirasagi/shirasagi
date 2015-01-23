require 'webrick'
require 'thread'

class Voice::TestHttpServer
  public
    def initialize(port)
      @port = port
      @fixture_root = "#{Rails.root}/spec/fixtures/voice"
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

  private
    def set_started
      @lock.synchronize do
        @flag = true
        @cond.broadcast
      end
    end

    def handle(request, response)
      path = "#{@fixture_root}/#{request.path}"
      path.gsub!(/\/\/+/, "/")

      raise WEBrick::HTTPStatus::NotFound unless ::File.exist?(path)

      file = ::File.new(path)
      status_code = request.query['status_code'].present? ? request.query['status_code'].to_i : nil
      last_modified = request.query['last_modified'].present? ? request.query['last_modified'] : nil
      last_modified = parse_last_modified(last_modified, ::File.mtime(path).httpdate)
      etag = request.query['etag'].present? ? request.query['etag'] : make_etag(file)
      wait = request.query['wait'].present? ? request.query['wait'].to_f : nil
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

      response.status = status_code if status_code
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
