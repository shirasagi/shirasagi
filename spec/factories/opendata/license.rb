FactoryGirl.define do
  factory :opendata_license, class: Opendata::License do
    name { unique_id }
    cur_site { cms_site }
  end
end
