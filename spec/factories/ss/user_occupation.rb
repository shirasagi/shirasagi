FactoryBot.define do
  factory :ss_user_occupation, class: SS::UserOccupation do
    code { "code-#{unique_id}" }
    name { "name-#{unique_id}" }
    remark { "remark-#{unique_id}" }
  end
end
