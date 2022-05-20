FactoryBot.define do
  factory :cms_member, class: Cms::Member do
    cur_site { cms_site }
    name { unique_id.to_s }
    email { "#{name}@example.jp" }
    in_password { "abc123" }
  end

  factory :cms_line_member, class: Cms::Member do
    cur_site { cms_site }
    name { unique_id.to_s }
    oauth_id { unique_id }
    oauth_type { "line" }
    subscribe_line_message { "active" }
  end
end
