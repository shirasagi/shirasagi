require 'docker'

module SS::LdapSupport
  module_function

  BOOTSTRAP_LDIFS = %w(10-ss-schema 11-member-of).freeze

  def ldap_test_enabled?
    ENV["LDAP_TEST"] == "enable" || ci?
  end

  def ldap_test_disabled?
    !ldap_test_enabled?
  end

  def docker_conf
    @docker_conf ||= {}
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
    RSpec.configuration.include(SS::LdapSupport, js: true)
  rescue
    RSpec.configuration.filter_run_excluding(ldap: true)
  end

  def before_example
    SS::LdapSupport.start_ldap_service

    path = Rails.root.join("spec/fixtures/ldap/shirasagi.ldif")
    SS::LdapSupport.ldap_add path
  end

  def after_suite
    SS::LdapSupport.stop_ldap_service
  end

  def start_ldap_service
    container = SS::LdapSupport.docker_container
    # already started
    return if container.present?

    image_id = SS::LdapSupport.docker_conf_image_id
    ldap_port = rand(21_000..21_499)
    ldaps_port = rand(21_500..21_999)
    container = Docker::Container.create(
      'Image' => image_id,
      'ExposedPorts' => { '389/tcp' => {}, '636/tcp' => {} },
      'Env' => %w(LDAP_ORGANISATION=shirasagi LDAP_DOMAIN=example.jp),
      'Cmd' => [ "--copy-service" ],
      'HostConfig' => {
        'Binds' => BOOTSTRAP_LDIFS.map do |ldif|
          "#{Rails.root}/spec/fixtures/ldap/#{ldif}.ldif:/container/service/slapd/assets/config/bootstrap/ldif/#{ldif}.ldif"
        end,
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

    SS::LdapSupport.docker_container = container
    SS::LdapSupport.docker_ldap_port = ldap_port
    SS::LdapSupport.docker_ldaps_port = ldaps_port

    ::Ldap.url = "ldap://localhost:#{ldap_port}/"

    puts "image '#{image_id}' successfully launched as container '#{container.id[0, 12]}' listening on #{ldap_port}"
  end

  def stop_ldap_service
    container = SS::LdapSupport.docker_container
    # already stopped
    return if container.blank?

    SS::LdapSupport.docker_container = nil
    SS::LdapSupport.docker_ldap_port = nil
    SS::LdapSupport.docker_ldaps_port = nil
    container.stop
    container.delete(force: true)
    puts "container '#{container.id[0, 12]}' is deleted"
  end

  def ldap_command(command, path_or_data)
    container = SS::LdapSupport.docker_container
    return unless container

    case path_or_data
    when Pathname
      container.store_file("/data.ldif", ::File.read(path_or_data))
    when File
      container.store_file("/data.ldif", path_or_data.read)
    when String
      container.store_file("/data.ldif", path_or_data)
    else
      raise "invalid data"
    end
    _stdout, stderr, exit_code = container.exec(%W(#{command} -Y EXTERNAL -H ldapi:/// -f /data.ldif))
    if exit_code != 0
      puts "[Error] failed to execute '#{command}'"
      puts stderr.join("\n") if stderr
    end
  end

  def ldap_add(path_or_data)
    ldap_command("/usr/bin/ldapadd", path_or_data)
  end

  def ldap_modify(path_or_data)
    ldap_command("/usr/bin/ldapmodify", path_or_data)
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
