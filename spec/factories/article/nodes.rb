FactoryBot.define do
  factory :article_node_base, class: Article::Node::Base, traits: [:cms_node] do
    route { "article/base" }
  end

  factory :article_node_page, class: Article::Node::Page, traits: [:cms_node] do
    route { "article/page" }

    factory :article_node_page_basename_invalid do
      basename { "no/de" }
    end
  end

  factory :article_node_search, class: Article::Node::Search, traits: [:cms_node] do
    route { "article/search" }
  end
end
