def can_test_ldap_spec?
  return false if ENV["ldap_host"].blank?
  true
end
