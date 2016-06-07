FactoryGirl.define do
  factory :cms_member, class: Cms::Member do
    site_id { cms_site.id }
    name { unique_id.to_s }
    email { "#{name}@example.jp" }
    in_password "abc123"
  end
end
