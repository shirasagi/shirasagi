FactoryGirl.define do
  factory :article_page, class: Article::Page, traits: [:cms_page] do
    route "article/page"
  end
end
