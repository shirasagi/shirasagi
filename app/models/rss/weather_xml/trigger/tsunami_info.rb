# 津波情報
class Rss::WeatherXml::Trigger::TsunamiInfo < Rss::WeatherXml::Trigger::Base
  include Rss::WeatherXml::Trigger::TsunamiBase

  self.control_title = '津波情報'
end
