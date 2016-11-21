FactoryGirl.define do
  trait :rss_weather_xml_trigger_base do
    cur_site { cms_site }
    name { unique_id }
    training_status 'disabled'
    test_status 'disabled'
  end

  factory :rss_weather_xml_trigger_quake_intensity_flash,
          class: Jmaxml::Trigger::QuakeIntensityFlash, traits: [:rss_weather_xml_trigger_base] do
    earthquake_intensity '5+'
  end

  factory :rss_weather_xml_trigger_quake_info,
          class: Jmaxml::Trigger::QuakeInfo, traits: [:rss_weather_xml_trigger_base] do
    earthquake_intensity '5+'
  end

  factory :rss_weather_xml_trigger_tsunami_alert,
          class: Jmaxml::Trigger::TsunamiAlert, traits: [:rss_weather_xml_trigger_base]

  factory :rss_weather_xml_trigger_tsunami_info,
          class: Jmaxml::Trigger::TsunamiInfo, traits: [:rss_weather_xml_trigger_base]

  factory :rss_weather_xml_trigger_weather_alert,
          class: Jmaxml::Trigger::WeatherAlert, traits: [:rss_weather_xml_trigger_base] do
    sub_types %w(special_alert alert warning)
  end

  factory :rss_weather_xml_trigger_landslide_info,
          class: Jmaxml::Trigger::LandslideInfo, traits: [:rss_weather_xml_trigger_base]

  factory :rss_weather_xml_trigger_flood_forecast,
          class: Jmaxml::Trigger::FloodForecast, traits: [:rss_weather_xml_trigger_base]

  factory :rss_weather_xml_trigger_volcano_flash,
          class: Jmaxml::Trigger::VolcanoFlash, traits: [:rss_weather_xml_trigger_base]

  factory :rss_weather_xml_trigger_ash_fall_forecast,
          class: Jmaxml::Trigger::AshFallForecast, traits: [:rss_weather_xml_trigger_base] do
    sub_types %w(flash regular detail)
  end

  factory :rss_weather_xml_trigger_tornado_alert,
          class: Jmaxml::Trigger::TornadoAlert, traits: [:rss_weather_xml_trigger_base]
end
