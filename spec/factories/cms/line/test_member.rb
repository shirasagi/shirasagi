FactoryBot.define do
  factory :cms_line_test_member, class: Cms::Line::TestMember do
    site { cms_site }
    name { unique_id }
    oauth_id { unique_id }
  end
end
