FactoryBot.define do
  trait :jmaxml_trigger_base do
    cur_site { cms_site }
    name { unique_id }
    training_status 'disabled'
    test_status 'disabled'
  end

  factory :jmaxml_trigger_quake_intensity_flash,
          class: Jmaxml::Trigger::QuakeIntensityFlash, traits: [:jmaxml_trigger_base] do
    earthquake_intensity '5+'
  end

  factory :jmaxml_trigger_quake_info,
          class: Jmaxml::Trigger::QuakeInfo, traits: [:jmaxml_trigger_base] do
    earthquake_intensity '5+'
  end

  factory :jmaxml_trigger_tsunami_alert,
          class: Jmaxml::Trigger::TsunamiAlert, traits: [:jmaxml_trigger_base] do
    sub_types %w(special_alert alert warning)
  end

  factory :jmaxml_trigger_tsunami_info,
          class: Jmaxml::Trigger::TsunamiInfo, traits: [:jmaxml_trigger_base] do
    sub_types %w(special_alert alert warning)
  end

  factory :jmaxml_trigger_weather_alert,
          class: Jmaxml::Trigger::WeatherAlert, traits: [:jmaxml_trigger_base] do
    sub_types %w(special_alert alert warning)
  end

  factory :jmaxml_trigger_landslide_info,
          class: Jmaxml::Trigger::LandslideInfo, traits: [:jmaxml_trigger_base]

  factory :jmaxml_trigger_flood_forecast,
          class: Jmaxml::Trigger::FloodForecast, traits: [:jmaxml_trigger_base]

  factory :jmaxml_trigger_volcano_flash,
          class: Jmaxml::Trigger::VolcanoFlash, traits: [:jmaxml_trigger_base]

  factory :jmaxml_trigger_ash_fall_forecast,
          class: Jmaxml::Trigger::AshFallForecast, traits: [:jmaxml_trigger_base] do
    sub_types %w(flash regular detail)
  end

  factory :jmaxml_trigger_tornado_alert,
          class: Jmaxml::Trigger::TornadoAlert, traits: [:jmaxml_trigger_base]
end
