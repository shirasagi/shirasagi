FactoryGirl.define do
  factory :ss_site, class: SS::Site do
    name "#{unique_id}"
    host "test-#{unique_id}"
    domains "test#{unique_id}.com"
    #group_id 1
  end
end
