require 'docker'

module SS::MicheckerSupport
  module_function

  def docker_image_id
    "shirasagi/michecker"
  end

  def init
    Docker::Image.get(SS::MicheckerSupport.docker_image_id)
  rescue => e
    puts("[Michecker Spec] failed to initialize")
    puts("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    RSpec.configuration.filter_run_excluding(michecker: true)
  end
end

SS::MicheckerSupport.init
