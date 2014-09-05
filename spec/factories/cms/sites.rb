FactoryGirl.define do
  factory :cms_site, class: SS::Site do
    name "Sample Site"
    host "www"
    domains "www.localhost.com"
    #group_id 1
  end
end
