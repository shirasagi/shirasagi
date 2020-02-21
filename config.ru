# This file is used by Rack-based servers to start the application.

if Module.const_defined?(:Unicorn)
  # Unicorn self-process killer
  require 'unicorn/worker_killer'

  # Max requests per worker
  request_min = (ENV['UNICORN_KILLER_REQUEST_MIN'] || 3072).to_i
  request_max = (ENV['UNICORN_KILLER_REQUEST_MAX'] || 4096).to_i
  use Unicorn::WorkerKiller::MaxRequests, request_min, request_max

  # Max memory size (RSS) per worker
  mem_min = (ENV['UNICORN_KILLER_MEM_MIN'] || 512).to_i
  mem_max = (ENV['UNICORN_KILLER_MEM_MAX'] || 576).to_i
  use Unicorn::WorkerKiller::Oom, (mem_min*(1024**2)), (mem_max*(1024**2))
end

require ::File.expand_path('../config/environment', __FILE__)
run Rails.application
