FactoryGirl.define do
  factory :key_visual_node_image, class: KeyVisual::Node::Image, traits: [:cms_node] do
    route "key_visual/image"
  end
end
