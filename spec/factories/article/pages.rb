FactoryGirl.define do
  factory :article_page, class: Article::Page, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "article/page"
  end
end
