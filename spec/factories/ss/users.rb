FactoryGirl.define do
  factory :ss_user, class: SS::User do
    sequence(:name) { |n| "name#{n}" }
    sequence(:email) { |n| "name#{n}@example.jp" }
    in_password "pass"
    #group_ids [1]
  end
  
  trait :ss_user do
    user_id do
      build(:ss_user).save unless SS::User.exists?
      SS::User.first.id
    end
  end
end
