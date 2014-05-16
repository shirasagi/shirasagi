# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ss_user, :class => 'SS::User' do
    name  "testuser"
    sequence(:email) {|i| "test#{i}@example.jp"}
    password "password"
    group_ids [1]
  end
end
