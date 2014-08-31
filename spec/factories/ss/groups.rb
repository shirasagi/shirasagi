FactoryGirl.define do
  factory :ss_group, class: SS::Group do
    sequence(:name) { |n| "name#{n}" }
  end
end
