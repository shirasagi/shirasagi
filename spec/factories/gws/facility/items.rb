FactoryGirl.define do
  factory :gws_facility_item, class: Gws::Facility::Item do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
  end
end
