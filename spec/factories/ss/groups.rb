FactoryGirl.define do
  factory :ss_group, class: SS::Group do
    name "#{unique_id}"
  end
end
