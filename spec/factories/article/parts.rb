FactoryBot.define do
  factory :article_part_page, class: Article::Part::Page, traits: [:cms_part] do
    route { "article/page" }

    factory :article_part_page_basename_invalid do
      basename { "pa/rt" }
    end
  end

  factory :article_part_search, class: Article::Part::Search, traits: [:cms_part] do
    route { "article/search" }
  end
end
