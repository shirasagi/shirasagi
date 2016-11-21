FactoryGirl.define do
  trait :rss_weather_xml_trigger_base do
    cur_site { cms_site }
    name { unique_id }
    training_status 'disabled'
    test_status 'disabled'
  end

  factory :rss_weather_xml_trigger_quake_intensity_flash,
          class: Rss::WeatherXml::Trigger::QuakeIntensityFlash, traits: [:rss_weather_xml_trigger_base] do
    earthquake_intensity '5+'
  end

  factory :rss_weather_xml_trigger_quake_info,
          class: Rss::WeatherXml::Trigger::QuakeInfo, traits: [:rss_weather_xml_trigger_base] do
    earthquake_intensity '5+'
  end

  factory :rss_weather_xml_trigger_tsunami_alert,
          class: Rss::WeatherXml::Trigger::TsunamiAlert, traits: [:rss_weather_xml_trigger_base]

  factory :rss_weather_xml_trigger_tsunami_info,
          class: Rss::WeatherXml::Trigger::TsunamiInfo, traits: [:rss_weather_xml_trigger_base]

  factory :rss_weather_xml_trigger_weather_alert,
          class: Rss::WeatherXml::Trigger::WeatherAlert, traits: [:rss_weather_xml_trigger_base]

  factory :rss_weather_xml_trigger_landslide_info,
          class: Rss::WeatherXml::Trigger::LandslideInfo, traits: [:rss_weather_xml_trigger_base]

  factory :rss_weather_xml_trigger_flood_forecast,
          class: Rss::WeatherXml::Trigger::FloodForecast, traits: [:rss_weather_xml_trigger_base]

  factory :rss_weather_xml_trigger_volcano_flash,
          class: Rss::WeatherXml::Trigger::VolcanoFlash, traits: [:rss_weather_xml_trigger_base]

  factory :rss_weather_xml_trigger_ash_fall_forecast,
          class: Rss::WeatherXml::Trigger::AshFallForecast, traits: [:rss_weather_xml_trigger_base] do
    sub_types %w(flash regular detail)
  end

  factory :rss_weather_xml_trigger_tornado_alert,
          class: Rss::WeatherXml::Trigger::TornadoAlert, traits: [:rss_weather_xml_trigger_base]
end
