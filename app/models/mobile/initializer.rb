module Mobile
  class Initializer
    Cms::PublicFilter.prepend Mobile::PublicFilter
  end
end
