class Ldap::Config
  cattr_reader(:default_values) do
    {
      host: "localhost:389",
      auth_method: "simple",
      exclude_groups: []
    }
  end
end
