FactoryBot.define do
  factory :lsorg_node_node, class: Lsorg::Node::Node, traits: [:cms_node] do
    cur_site { cms_site }
    route { "lsorg/node" }
  end

  factory :lsorg_node_page, class: Lsorg::Node::Page, traits: [:cms_node] do
    cur_site { cms_site }
    route { "lsorg/page" }
  end
end
