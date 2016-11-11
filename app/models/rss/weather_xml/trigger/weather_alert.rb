class Rss::WeatherXml::Trigger::WeatherAlert < Rss::WeatherXml::Trigger::Base
  field :kind_warning, type: String
  field :kind_advisory, type: String
  embeds_ids :target_regions, class_name: "Rss::WeatherXml::ForecastRegion"
  permit_params :kind_warning, :kind_advisory
  permit_params target_region_ids: []
end
