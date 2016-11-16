# 震源・震度に関する情報
class Rss::WeatherXml::Trigger::QuakeInfo < Rss::WeatherXml::Trigger::Base
  include Rss::WeatherXml::Trigger::QuakeBase

  self.control_title = '震源・震度に関する情報'
end
