module Jmaxml::Type
  class EarthQuake
    def renderer(page, context)
      Jmaxml::Renderer::Quake.new(page, context)
    end

    def mailer
      Jmaxml::Mailer::Quake
    end
  end

  class Tsunami
    def renderer(page, context)
      Jmaxml::Renderer::Tsunami.new(page, context)
    end

    def mailer
      Jmaxml::Mailer::Tsunami
    end
  end

  class Flood
    def renderer(page, context)
      Jmaxml::Renderer::Flood.new(page, context)
    end

    def mailer
      Jmaxml::Mailer::Flood
    end
  end

  class Forecast
    def renderer(page, context)
      Jmaxml::Renderer::Forecast.new(page, context)
    end

    def mailer
      Jmaxml::Mailer::Forecast
    end
  end

  class Landslide
    def renderer(page, context)
      Jmaxml::Renderer::Landslide.new(page, context)
    end

    def mailer
      Jmaxml::Mailer::Landslide
    end
  end

  class Volcano
    def renderer(page, context)
      Jmaxml::Renderer::Volcano.new(page, context)
    end

    def mailer
      Jmaxml::Mailer::Volcano
    end
  end

  class Tornado
    def renderer(page, context)
      Jmaxml::Renderer::Tornado.new(page, context)
    end

    def mailer
      Jmaxml::Mailer::Tornado
    end
  end

  class AshFall
    def renderer(page, context)
      Jmaxml::Renderer::AshFall.new(page, context)
    end

    def mailer
      Jmaxml::Mailer::AshFall
    end
  end

  EARTH_QUAKE = EarthQuake.new.freeze
  TSUNAMI = Tsunami.new.freeze
  FLOOD = Flood.new.freeze
  FORECAST = Forecast.new.freeze
  LAND_SLIDE = Landslide.new.freeze
  VOLCANO = Volcano.new.freeze
  TORNADO = Tornado.new.freeze
  ASH_FALL = AshFall.new.freeze
end
