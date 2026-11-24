require 'docker'

module SS::LdapSupport
  module_function

  def ldap_test_enabled?
    ENV["LDAP_TEST"] == "enable"
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

  def docker_config_password
    @docker_config_password
  end

  def docker_config_password=(value)
    @docker_config_password = value
  end

  def docker_database_password
    @docker_database_password
  end

  def docker_database_password=(value)
    @docker_database_password = value
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
      'ExposedPorts' => { '3890/tcp' => {}, '6360/tcp' => {} },
      'Env' => %w(OPENLDAP_BOOTSTRAP_ORGANIZATION=shirasagi OPENLDAP_BOOTSTRAP_SUFFIX=dc=example,dc=jp),
      'HostConfig' => {
        'PortBindings' => {
          '3890/tcp' => [{ 'HostPort' => ldap_port.to_s }],
          '6360/tcp' => [{ 'HostPort' => ldaps_port.to_s }]
        }
      }
    )
    container.start
    config_password = nil
    database_password = nil
    Timeout.timeout(60) do
      loop do
        logs = container.logs(stdout: true)
        if logs.include?("Running /container/services/openldap/process.sh")
          config_password = $1 if logs.match(/Generated config root password:\s+(\S+)/)
          database_password = $1 if logs.match(/Generated database root password:\s+(\S+)/)
          break
        end

        sleep 1
      end
    end

    ldif = ::File.read(Rails.root.join("spec/fixtures/ldap/shirasagi.ldif"))
    ldif.gsub!("pass", ss_pass)
    container.store_file("/shirasagi.ldif", ldif)

    ldap_add_commands = [
      "ldapadd", "-H", "ldap://:3890", "-D", "cn=admin,dc=example,dc=jp",
      "-w", database_password, "-f", "/shirasagi.ldif"
    ]
    stdout, stderr, exit_code = container.exec(ldap_add_commands, user: 'root')
    if exit_code != 0
      puts "[Error] failed to execute 'ldapadd'"
      puts stdout.join if stdout
      puts stderr.join if stderr
      container.stop
      container.delete(force: true)
      return
    end

    SS::LdapSupport.docker_container = container
    SS::LdapSupport.docker_ldap_port = ldap_port
    SS::LdapSupport.docker_ldaps_port = ldaps_port
    SS::LdapSupport.docker_config_password = config_password
    SS::LdapSupport.docker_database_password = database_password

    ::Ldap.url = "ldap://localhost:#{ldap_port}/"
    ::Ldap.auth_method = :simple
    ::Ldap.admin_user = "cn=admin,dc=example,dc=jp"
    ::Ldap.admin_password = database_password

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
