FactoryGirl.define do
  factory :cms_member, class: Cms::Member do
    site_id { cms_site.id }
    name "#{unique_id}"
    email { "#{name}@example.jp" }
    in_password "pass"
  end
end
