FactoryGirl.define do
  factory :ss_site, class: SS::Site do
    name "#{unique_id}"
    host "www-#{unique_id}"
    domains "www#{unique_id}.com"
    #group_id 1
  end
end
