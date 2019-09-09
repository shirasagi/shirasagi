require 'docker'

module SS::LdapSupport
  module_function

  def ldap_test_enabled?
    ENV["LDAP_TEST"] == "enable" || travis?
  end

  def ldap_test_disabled?
    !ldap_test_enabled?
  end

  def docker_conf
    @docker_conf ||= SS.config.ldap.test_docker || {}
  end

  def docker_conf_api_url
    SS::LdapSupport.docker_conf["api_url"].presence
  end

  def docker_conf_image_id
    SS::LdapSupport.docker_conf["image_id"].presence || "osixia/openldap"
  end

  def docker_container
    @docker_container
  end

  def docker_container=(value)
    @docker_container = value
  end

  def docker_ldap_port
    @docker_ldap_port
  end

  def docker_ldap_port=(value)
    @docker_ldap_port = value
  end

  def docker_ldaps_port
    @docker_ldaps_port
  end

  def docker_ldaps_port=(value)
    @docker_ldaps_port = value
  end

  def init
    if SS::LdapSupport.ldap_test_disabled?
      RSpec.configuration.filter_run_excluding(ldap: true)
      return
    end

    api_url = SS::LdapSupport.docker_conf_api_url
    Docker.url = api_url if api_url.present?

    image_id = SS::LdapSupport.docker_conf_image_id
    version = Docker.version["Version"]
    puts "found docker #{version} and image '#{image_id}'"

    RSpec.configuration.extend(SS::LdapSupport::EventHandler, ldap: true)
    RSpec.configuration.after(:suite) do
      SS::LdapSupport.after_suite
    end
  rescue
    RSpec.configuration.filter_run_excluding(ldap: true)
  end

  def before_example
    container = SS::LdapSupport.docker_container
    return if container.present?

    image_id = SS::LdapSupport.docker_conf_image_id
    ldap_port = rand(21_000..21_499)
    ldaps_port = rand(21_500..21_999)
    container = Docker::Container.create(
      'Image' => image_id,
      'ExposedPorts' => { '389/tcp' => {}, '636/tcp' => {} },
      'Env' => %w(LDAP_ORGANISATION=shirasagi LDAP_DOMAIN=example.jp),
      'HostConfig' => {
        'PortBindings' => {
          '389/tcp' => [{ 'HostPort' => ldap_port.to_s }],
          '636/tcp' => [{ 'HostPort' => ldaps_port.to_s }]
        }
      }
    )
    container.start
    Timeout.timeout(60) do
      loop do
        break if container.logs(stdout: true).include?("First start is done")

        sleep 0.1
      end
    end

    container.store_file("/shirasagi.ldif", ::File.read(Rails.root.join("spec/fixtures/ldap/shirasagi.ldif")))
    _stdout, _stderr, exit_code = container.exec(%w(ldapadd -D cn=admin,dc=example,dc=jp -w admin -f /shirasagi.ldif))
    if exit_code != 0
      puts "[Error] failed to execute 'ldapadd'"
      container.stop
      container.delete(force: true)
      return
    end

    SS::LdapSupport.docker_container = container
    SS::LdapSupport.docker_ldap_port = ldap_port
    SS::LdapSupport.docker_ldaps_port = ldaps_port

    SS.config.replace_value_at(:ldap, :host, "localhost:#{ldap_port}")

    puts "image '#{image_id}' successfully launched as container '#{container.id[0, 12]}' listening on #{ldap_port}"
  end

  def after_suite
    container = SS::LdapSupport.docker_container
    return if container.blank?

    SS::LdapSupport.docker_container = nil
    container.stop
    container.delete(force: true)
    puts "container '#{container.id[0, 12]}' is deleted"
  end

  module EventHandler
    extend ActiveSupport::Concern

    def self.extended(obj)
      obj.before(:example) do
        SS::LdapSupport.before_example
      end
    end
  end
end

SS::LdapSupport.init
