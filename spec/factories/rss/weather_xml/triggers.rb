FactoryGirl.define do
  trait :rss_weather_xml_trigger_base do
    cur_site { cms_site }
    name { unique_id }
    training_status 'disabled'
    test_status 'disabled'
  end

  factory :rss_weather_xml_trigger_quake_intensity_flash, class: Rss::WeatherXml::Trigger::QuakeIntensityFlash, traits: [:rss_weather_xml_trigger_base] do
    earthquake_intensity '5+'
  end
end
