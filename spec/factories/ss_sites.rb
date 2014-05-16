# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ss_site, :class => 'SS::Site' do
    name  "Test Site"
    sequence(:host) {|i| "www#{i}"}
    domains ["testsite:3000"]
    group_id 1
  end
end
