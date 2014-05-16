# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :cms_node, :class => 'Cms::Node' do
    state  "public"
    name   "テスト"
    filename "test/fukushi"
    route  "category/pages"
    site_id 1
  end
end
