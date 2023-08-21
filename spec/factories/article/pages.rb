FactoryBot.define do
  factory :article_page, class: Article::Page, traits: [:cms_page] do
    route { "article/page" }
    keywords { "#{unique_id} #{unique_id}" }
    description { unique_id.to_s }

    factory :article_page_basename_invalid do
      basename { "pa/ge.html" }
    end

    factory :article_page_10_characters_name do
      name { "a" * 10 }
    end

    factory :article_page_100_characters_name do
      name { "b" * 100 }
    end

    factory :article_page_1000_characters_name do
      name { "c" * 1000 }
    end
  end
end
