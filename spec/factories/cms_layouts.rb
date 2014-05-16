# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :cms_layout, :class => 'Cms::Layout' do
    state  "public"
    name   "テストレイアウト"
    filename "test.layout.html"
    depth  1
    html   ""
    site_id  1
  end
end
