FactoryGirl.define do
  factory :article_node_base, class: Article::Node::Base, traits: [:cms_node] do
    route "article/base"
  end

  factory :article_node_page, class: Article::Node::Page, traits: [:cms_node] do
    route "article/page"
  end
end
