def can_test_ldap_spec?
  return false if ENV["ldap_host"].blank?
  true
end

RSpec.configuration.before(:suite) do
  SS.config.replace_value_at(:ldap, :host, ENV["ldap_host"]) if ENV["ldap_host"].present?
end

RSpec.configuration.filter_run_excluding(ldap: true) unless can_test_ldap_spec?
