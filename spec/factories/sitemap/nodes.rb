FactoryGirl.define do
  factory :sitemap_node_base, class: Sitemap::Node::Base, traits: [:cms_node] do
    route "sitemap/base"
  end

  factory :sitemap_node_page, class: Sitemap::Node::Page, traits: [:cms_node] do
    route "sitemap/page"
  end
end
