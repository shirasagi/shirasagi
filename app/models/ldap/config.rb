class Ldap::Config
  cattr_reader(:default_values) do
    {
      host: "localhost"
    }
  end
end
