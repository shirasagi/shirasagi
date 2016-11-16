class Rss::WeatherXml::Trigger::FloodForecast < Rss::WeatherXml::Trigger::Base
  embeds_ids :target_regions, class_name: "Rss::WeatherXml::WaterLevelStation"
  permit_params target_region_ids: []
end
