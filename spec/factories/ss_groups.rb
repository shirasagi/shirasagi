# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ss_group, :class => 'SS::Group' do
    name  "testgroup"
  end
end
