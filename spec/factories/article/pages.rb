FactoryGirl.define do
  factory :article_page, class: Article::Page, traits: [:ss_site, :ss_user] do
    sequence(:name) { |n| "name#{n}" }
    sequence(:filename) { |n| "docs/file#{n}.html" }
    route "article/page"
  end
end
