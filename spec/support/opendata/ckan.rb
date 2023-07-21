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
    "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJBQVNLX19lQUMwQ3dxV0VjNXZKcW9hQy1zbWt1dExaU0NORWotMzlYZVZBIiwiaWF0IjoxNjg5ODM1ODMyfQ.rWZGXCfSVDN9jISBcJ8qlyVq_bMKKPOokKdUOe65LJ4"
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
    puts("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    RSpec.configuration.filter_run_excluding(ckan: true)
  end

  def before_example
    container = SS::CkanSupport.docker_container
    return if container.present?

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
        break if container.logs(stdout: true).include?("Starting nginx nginx")

        sleep 0.1
      end
    end

    SS::CkanSupport.docker_container = container
    SS::CkanSupport.docker_ckan_port = ckan_port

    puts "image '#{image_id}' successfully launched as container '#{container.id[0, 12]}' listening on #{ckan_port}"
  end

  def after_suite
    container = SS::CkanSupport.docker_container
    return if container.blank?

    SS::CkanSupport.docker_container = nil
    container.stop
    container.delete(force: true)
    puts "container '#{container.id[0, 12]}' is deleted"
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
