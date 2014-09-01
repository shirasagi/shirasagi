FactoryGirl.define do
  factory :ss_user, class: SS::User do
    name "#{unique_id}"
    email "#{unique_id}@example.jp"
    in_password "pass"
    #group_ids [1]
  end
end
