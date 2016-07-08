FactoryGirl.define do
  factory :cms_member, class: Cms::Member do
    cur_site { cms_site }
    name { unique_id.to_s }
    email { "#{name}@example.jp" }
    in_password "abc123"
  end
end
