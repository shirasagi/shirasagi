def can_test_ldap_spec?
  return false if ENV["ldap_host"].blank?
  true
end

RSpec.configuration.before(:suite) do
  SS::Config.replace_value_at(:ldap, :host, ENV["ldap_host"]) if ENV["ldap_host"].present?
end
