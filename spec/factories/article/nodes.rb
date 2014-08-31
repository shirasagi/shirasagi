FactoryGirl.define do
  factory :article_node_base, class: Article::Node::Base, traits: [:ss_site, :ss_user, :cms_node] do
    route "article/base"
  end

  factory :article_node_page, class: Article::Node::Page, traits: [:ss_site, :ss_user, :cms_node] do
    route "article/page"
  end
end
