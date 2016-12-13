class Jmaxml::Renderer::Forecast < Jmaxml::Renderer::Main
  include Jmaxml::Helper::Forecast

  def jmaxml_type
    :forecast
  end
end
