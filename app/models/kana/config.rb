class Kana::Config
  cattr_reader(:default_values) do
    {
      disable: false,
      location: "/kana"
    }
  end
end
