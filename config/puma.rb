# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.
#
# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
#
# You can control the number of workers using ENV["WEB_CONCURRENCY"]. You
# should only set this value when you want to run 2 or more workers. The
# default is already 1.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

worker_timeout ENV.fetch("WORKER_TIMEOUT", 120)

before_fork do
  require 'puma_worker_killer'

  PumaWorkerKiller.config do |config|
    # see: https://github.com/zombocom/puma_worker_killer
    config.ram           = ENV.fetch("PUMA_RAM", 1024).to_i # mb
    config.frequency     = 60 # seconds
    config.percent_usage = 0.98
    # 12 hours in seconds, or 12.hours if using Rails
    config.rolling_restart_frequency = ENV.fetch("PUMA_ROLLING_RESTART_FREQUENCY", 12.hours).to_i
    config.reaper_status_logs = true # setting this to false will not log lines like:
    # PumaWorkerKiller: Consuming 54.34765625 mb with master and 2 workers.

    config.pre_term = ->(worker) { puts "Worker #{worker.inspect} being killed" }
    config.rolling_pre_term = ->(worker) { puts "Worker #{worker.inspect} being killed by rolling restart" }
  end

  PumaWorkerKiller.start
  puts "Puma Worker Killer started!"
end
