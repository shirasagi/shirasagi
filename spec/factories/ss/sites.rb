FactoryGirl.define do
  factory :ss_site, class: SS::Site do
    sequence(:name) { |n| "name#{n}" }
    sequence(:host) { |n| "www#{n}" }
    sequence(:domains, 3000) { |n| "localhost:#{n}" }
    #group_id 1
  end
  
  trait :ss_site do
    site_id do
      build(:ss_site).save unless SS::Site.exists?
      SS::Site.first.id
    end
  end
end
