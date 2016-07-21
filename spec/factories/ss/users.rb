FactoryGirl.define do
  factory :ss_user, class: SS::User do
    name "ss_user"
    email "ss@example.jp"
    in_password "pass"
    #group_ids [1]
  end

  factory :ss_user2, class: SS::User do
    name "user2"
    email "user2@example.jp"
    in_password "pass"
  end

  factory :ss_user3, class: SS::User do
    name "user3"
    email "user3@example.jp"
    in_password "pass"
  end

  factory :ss_user4, class: SS::User do
    name "user4"
    email "user4@example.jp"
    in_password "pass"
  end
end
