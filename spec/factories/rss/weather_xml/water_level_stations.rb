FactoryGirl.define do
  factory :rss_weather_xml_water_level_station_base, class: Rss::WeatherXml::WaterLevelStation do
    cur_site { cms_site }

    factory :rss_weather_xml_water_level_station_85050900020300042 do
      code "85050900020300042"
      name "岡島"
      region_name "揖斐川中流"
    end

    factory :rss_weather_xml_water_level_station_85050900020300045 do
      code "85050900020300045"
      name "万石"
      region_name "揖斐川中流"
    end

    factory :rss_weather_xml_water_level_station_85050900020300053 do
      code "85050900020300053"
      name "山口"
      region_name "揖斐川中流"
    end
  end
end
