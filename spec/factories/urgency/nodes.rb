FactoryGirl.define do
  factory :urgency_node_base, class: Urgency::Node::Base, traits: [:cms_node] do
    route "urgency/base"
  end

  factory :urgency_node_layout, class: Urgency::Node::Layout, traits: [:cms_node] do
    route "urgency/layout"
    #urgency_default_layout_id { create(:cms_layout).id }
    urgency_default_layout_id { 1 }
  end
end
