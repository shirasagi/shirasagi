require 'docker'

module SS::CkanSupport
  module_function

  def ckan_test_enabled?
    ENV["CKAN_TEST"] == "enable" || ci?
  end

  def ckan_test_disabled?
    !ckan_test_enabled?
  end

  def docker_image_id
    "shirasagi/ckan"
  end

  def docker_container_borrowed
    @docker_borrowed
  end

  def docker_container_borrowed=(borrowed)
    @docker_borrowed = borrowed
  end

  def docker_container
    @docker_container
  end

  def docker_container=(value)
    @docker_container = value
  end

  def docker_ckan_port
    @docker_ckan_port
  end

  def docker_ckan_port=(value)
    @docker_ckan_port = value
  end

  def docker_ckan_api_key
    @docker_ckan_api_key ||= SS.config.opendata.dig("harvest", "docker_ckan_api_key")
  end

  def init
    if SS::CkanSupport.ckan_test_disabled?
      RSpec.configuration.filter_run_excluding(ckan: true)
      return
    end

    #api_url = SS::LdapSupport.docker_conf_api_url
    #Docker.url = api_url if api_url.present?

    image_id = docker_image_id
    version = Docker.version["Version"]
    puts "found docker #{version} and image '#{image_id}'"

    RSpec.configuration.extend(SS::CkanSupport::EventHandler, ckan: true)
    RSpec.configuration.after(:suite) do
      SS::CkanSupport.after_suite
    end
  rescue => e
    puts("[CKAN Spec] failed to initialize")
    RSpec.configuration.filter_run_excluding(ckan: true)
  end

  def before_example
    container = SS::CkanSupport.docker_container
    return if container.present? # already running

    ENV["CKAN_CONTAINER_ID"].try do |container_id|
      if container_id.present?
        container = Docker::Container.get(container_id) rescue nil
      end
      if container
        SS::CkanSupport.docker_container_borrowed = true
        SS::CkanSupport.docker_container = container
        ckan_port = container.info["HostConfig"]["PortBindings"]["80/tcp"][0]["HostPort"].to_i
        SS::CkanSupport.docker_ckan_port = ckan_port

        puts "use container '#{container.id[0, 12]}' as '#{docker_image_id}' listening on #{ckan_port}"
      end
    end

    container = SS::CkanSupport.docker_container
    return if container.present? # already running

    image_id = docker_image_id
    ckan_port = 8080
    container = Docker::Container.create(
      'Image' => image_id,
      'ExposedPorts' => { '80/tcp' => {} },
      'HostConfig' => {
        'PortBindings' => {
          '80/tcp' => [{ 'HostPort' => ckan_port.to_s }]
        }
      }
    )
    container.start
    Timeout.timeout(60) do
      loop do
        break if container.logs(stdout: true).include?("launch succeeded")
        sleep 0.1
      end
    end
    sleep 3

    SS::CkanSupport.docker_container_borrowed = false
    SS::CkanSupport.docker_container = container
    SS::CkanSupport.docker_ckan_port = ckan_port

    puts "image '#{image_id}' successfully launched as container '#{container.id[0, 12]}' listening on #{ckan_port}"
  end

  def after_suite
    container = SS::CkanSupport.docker_container
    return if container.blank?

    SS::CkanSupport.docker_container = nil
    unless SS::CkanSupport.docker_container_borrowed
      container.stop
      container.delete(force: true)
      puts "container '#{container.id[0, 12]}' is deleted"
    end
  end

  module EventHandler
    extend ActiveSupport::Concern

    def self.extended(obj)
      obj.before(:example) do
        SS::CkanSupport.before_example
      end
    end
  end
end

SS::CkanSupport.init
