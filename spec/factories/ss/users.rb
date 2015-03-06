FactoryGirl.define do
  factory :ss_user, class: SS::User do
    name "ss_user"
    email "ss@example.jp"
    in_password "pass"
    #group_ids [1]
  end
end
