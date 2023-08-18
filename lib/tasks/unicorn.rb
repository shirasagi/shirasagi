module Tasks
  class Unicorn
    extend ::FileUtils

    class << self
      def start
        conf = "#{Rails.root}/config/unicorn.rb"
        env  = ENV['RAILS_ENV'] || "development"
        sh "bundle exec unicorn_rails -c #{conf} -E #{env} -D"
      end

      def stop
        unicorn_signal :QUIT
      end

      def restart
        unicorn_signal :USR2
      end

      def increment
        unicorn_signal :TTIN
      end

      def decrement
        unicorn_signal :TTOU
      end

      def pstree
        sh "pstree '#{unicorn_pid}'"
      end

      private

      def unicorn_signal(signal)
        Process.kill(signal, unicorn_pid)
      end

      def unicorn_pid
        Integer(File.read("#{Rails.root}/tmp/pids/unicorn.pid"))
      rescue
        raise "Unicorn doesn't seem to be running"
      end
    end
  end
end
