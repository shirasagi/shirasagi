FactoryGirl.define do
  factory :ss_user_title, class: SS::UserTitle do
    name { "title-#{unique_id}" }
  end
end
