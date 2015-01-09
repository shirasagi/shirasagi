require 'webrick'
require 'thread'

class Voice::TestHttpServer
  public
    def initialize(port)
      @port = port
      @fixture_root = "#{Rails.root}/spec/fixtures/voice"
    end

    def start
      # puts "Voice::TestHttpServer#start"
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
        Signal.trap(:INT) { server.shutdown }
        server.start
      end

      wait
      # puts "Voice::TestHttpServer#start done"
    end

    def wait
      # puts "Voice::TestHttpServer#wait"
      @lock.synchronize do
        unless @started
          @cond.wait(@lock)
        end
      end
    end

    def stop
      Process.kill(:INT, Process.pid)
      @server_thread.join
      @server_thread = nil
    end

  private
    def set_started
      # puts "Voice::TestHttpServer#set_started"
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
      last_modified = request.query['last_modified'].present? ? Time.httpdate(request.query['last_modified']) : nil
      wait = request.query['wait'].present? ? request.query['wait'].to_i : nil
      sleep wait if wait

      response.status = status_code if status_code
      response.content_type = "text/html; charset=utf-8"
      response["Last-Modified"] = last_modified ? last_modified : ::File.mtime(path).httpdate
      response.body = file.read

    end
end
