FactoryGirl.define do
  factory :facility_image, class: Facility::Image, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "facility/image"
  end

  factory :facility_map, class: Facility::Map, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "facility/map"
  end
end
