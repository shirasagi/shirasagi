FactoryGirl.define do
  factory :article_page, class: Article::Page, traits: [:cms_page] do
    route "article/page"
    keywords { "#{unique_id} #{unique_id}" }
    description { "#{unique_id}" }
  end
end
