FactoryGirl.define do
  factory :ss_site, class: SS::Site do
    name "ss"
    host "test-ss"
    domains "test-ss.com"
    #group_id 1
  end
end
