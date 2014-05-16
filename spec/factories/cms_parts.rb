# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :cms_part, :class => 'Cms::Part' do
    state  "public"
    name   "テスト"
    filename "test.part.html"
    depth  1
    route  "cms/free"
    mobile_view  "show"
    site_id  1
  end
end
