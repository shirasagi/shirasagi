FactoryGirl.define do
  factory :gws_facility, class: Gws::Facility do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
  end
end
