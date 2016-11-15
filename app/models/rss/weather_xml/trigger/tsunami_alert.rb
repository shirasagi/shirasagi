# 津波警報・注意報・予報
class Rss::WeatherXml::Trigger::TsunamiAlert < Rss::WeatherXml::Trigger::Base
  include Rss::WeatherXml::Trigger::TsunamiBase

  self.control_title = '津波警報・注意報・予報'
end
