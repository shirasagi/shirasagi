module Jmaxml::Type
  class EarthQuake
    def renderer
      Jmaxml::Renderer::Quake
    end

    def mailer
      Jmaxml::Mailer::Quake
    end
  end

  class Tsunami
    def renderer
      Jmaxml::Renderer::Tsunami
    end

    def mailer
      Jmaxml::Mailer::Tsunami
    end
  end

  class Flood
    def renderer
      Jmaxml::Renderer::Flood
    end

    def mailer
      Jmaxml::Mailer::Flood
    end
  end

  class Forecast
    def renderer
      Jmaxml::Renderer::Forecast
    end

    def mailer
      Jmaxml::Mailer::Forecast
    end
  end

  class Landslide
    def renderer
      Jmaxml::Renderer::Landslide
    end

    def mailer
      Jmaxml::Mailer::Landslide
    end
  end

  class Volcano
    def renderer
      Jmaxml::Renderer::Volcano
    end

    def mailer
      Jmaxml::Mailer::Volcano
    end
  end

  class Tornado
    def renderer
      Jmaxml::Renderer::Tornado
    end

    def mailer
      Jmaxml::Mailer::Tornado
    end
  end

  class AshFall
    def renderer
      Jmaxml::Renderer::AshFall
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
