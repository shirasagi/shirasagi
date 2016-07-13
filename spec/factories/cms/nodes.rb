FactoryGirl.define do
  trait :cms_node do
    cur_site { cms_site }
    cur_user { cms_user }
    name { unique_id.to_s }
    filename { "node-#{unique_id}" }
    route "cms/node"
  end

  factory :cms_node, class: Cms::Node, traits: [:cms_node] do
    shortcut :show
  end

  factory :cms_node_base, class: Cms::Node::Base, traits: [:cms_node] do
    route "cms/base"
  end

  factory :cms_node_node, class: Cms::Node::Node, traits: [:cms_node] do
    route "cms/node"
  end

  factory :cms_node_page, class: Cms::Node::Page, traits: [:cms_node] do
    route "cms/page"
  end

  factory :cms_node_import_node, class: Cms::Node::ImportNode, traits: [:cms_node] do
    route "cms/import_node"
  end

  factory :cms_node_archive, class: Cms::Node::Archive, traits: [:cms_node] do
    route "cms/archive"
  end
end
