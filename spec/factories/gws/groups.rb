FactoryGirl.define do
  factory :gws_group, class: Gws::Group do
    name "group-#{unique_id}"
  end
end
