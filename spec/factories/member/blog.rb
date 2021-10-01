FactoryBot.define do
  factory :member_blog_page, class: Member::BlogPage, traits: [:cms_page] do
    route { "member/blog_page" }
    html { "<p>html</p>" }
  end
end
