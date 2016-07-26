FactoryGirl.define do
  factory :opendata_member, class: Opendata::Member do
    cur_site { cms_site }
    name { "#{unique_id}" }
    email { "#{name}@example.jp" }
    state "enabled"
    in_password "pass123"
  end
end
