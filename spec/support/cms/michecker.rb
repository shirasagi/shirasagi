require 'docker'

module SS::MicheckerSupport
  module_function

  def docker_image_id
    "shirasagi/michecker"
  end

  def init
    Docker::Image.get(SS::MicheckerSupport.docker_image_id)
  rescue Excon::Error::Socket => e
    Rails.logger.info("[Michecker Spec] #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    puts("[Michecker Spec] failed to initialize: the docker daemon may not be running")
    RSpec.configuration.filter_run_excluding(michecker: true)
  rescue => e
    Rails.logger.info("[Michecker Spec] #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    puts("[Michecker Spec] failed to initialize")
    RSpec.configuration.filter_run_excluding(michecker: true)
  end
end

SS::MicheckerSupport.init
