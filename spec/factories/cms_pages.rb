# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :cms_page, :class => 'Cms::Page' do
    state  "public"
    name   "テスト記事"
    sequence(:filename) {|i| "docs/test#{i}.html"}
    depth  2
    route  "cms/page"
    site_id  1
  end
end
