module Rss::Addon::WeatherXml::Trigger::WeatherAlert
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_one :trigger_weather_alert, class_name: "Rss::WeatherXml::Trigger::WeatherAlert"
    accepts_nested_attributes_for :trigger_weather_alert
    permit_params trigger_weather_alert: [ :kind_warning, :kind_advisory ]
  end

end
