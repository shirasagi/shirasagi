class Rss::WeatherXml::Trigger::LandslideInfo < Rss::WeatherXml::Trigger::Base
  embeds_ids :target_regions, class_name: "Rss::WeatherXml::ForecastRegion"
  permit_params target_region_ids: []
end
