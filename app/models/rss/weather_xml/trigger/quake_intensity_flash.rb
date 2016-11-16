# 震度速報
class Rss::WeatherXml::Trigger::QuakeIntensityFlash < Rss::WeatherXml::Trigger::Base
  include Rss::WeatherXml::Trigger::QuakeBase

  self.control_title = '震度速報'
end
