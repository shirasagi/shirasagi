FactoryGirl.define do
  factory :cms_site, class: Cms::Site do
    name "Site"
    host "test"
    domains "test.localhost.jp"
    #group_id 1
  end
end
