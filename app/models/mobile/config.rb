class Mobile::Config
  cattr_reader(:default_values) do
    {
      location: "/mobile"
    }
  end
end
