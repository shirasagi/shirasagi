module Rss
  class Initializer
    Cms::Node.plugin "rss/page"
    Cms::Node.plugin "rss/weather_xml"
  end
end
