class Rss::WeatherXml::Trigger::TsunamiAlert < Rss::WeatherXml::Trigger::Base
  embeds_ids :target_regions, class_name: "Rss::WeatherXml::TsunamiRegion"
  permit_params target_region_ids: []
end
