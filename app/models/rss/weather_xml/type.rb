module Rss::WeatherXml::Type
  class EarthQuake
    def renderer(page, context)
      Rss::WeatherXml::Renderer::Quake.new(page, context)
    end
  end

  class Tsunami
    def renderer(page, context)
      Rss::WeatherXml::Renderer::Tsunami.new(page, context)
    end
  end

  class Flood
    def renderer(page, context)
      raise NotImplementedError
    end
  end

  class Forecast
    def renderer(page, context)
      Rss::WeatherXml::Renderer::Forecast.new(page, context)
    end
  end

  class Landslide
    def renderer(page, context)
      raise NotImplementedError
    end
  end

  class Volcano
    def renderer(page, context)
      raise NotImplementedError
    end
  end

  EARTH_QUAKE = EarthQuake.new.freeze
  TSUNAMI = Tsunami.new.freeze
  FLOOD = Flood.new.freeze
  FORECAST = Forecast.new.freeze
  LAND_SLIDE = Landslide.new.freeze
  VOLCANO = Volcano.new.freeze
end
