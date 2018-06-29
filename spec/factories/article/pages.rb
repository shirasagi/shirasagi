FactoryBot.define do
  factory :article_page, class: Article::Page, traits: [:cms_page] do
    route "article/page"
    keywords { "#{unique_id} #{unique_id}" }
    description { unique_id.to_s }

    factory :article_page_basename_invalid do
      basename "pa/ge.html"
    end
  end
end
