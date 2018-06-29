FactoryBot.define do
  factory :jmaxml_water_level_station_base, class: Jmaxml::WaterLevelStation do
    cur_site { cms_site }

    factory :jmaxml_water_level_station_85050900020300042 do
      code "85050900020300042"
      name "岡島"
      region_name "揖斐川中流"
    end

    factory :jmaxml_water_level_station_85050900020300045 do
      code "85050900020300045"
      name "万石"
      region_name "揖斐川中流"
    end

    factory :jmaxml_water_level_station_85050900020300053 do
      code "85050900020300053"
      name "山口"
      region_name "揖斐川中流"
    end
  end
end
