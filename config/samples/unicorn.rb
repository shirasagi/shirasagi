# coding: utf-8
worker_processes Integer(ENV["WEB_CONCURRENCY"] || 2)
listen 3000
timeout 15
preload_app true

#stderr_path "log/unicorn.stderr.log"
#stdout_path "log/unicorn.stdout.log"

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      Process.kill :QUIT, File.read(old_pid).to_i
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
