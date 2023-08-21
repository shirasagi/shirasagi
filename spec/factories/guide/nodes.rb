FactoryBot.define do
  factory :guide_node_base, class: Guide::Node::Base, traits: [:cms_node] do
    route { "guide/base" }
  end

  factory :guide_node_guide, class: Guide::Node::Guide, traits: [:cms_node] do
    route { "guide/guide" }
  end
end
