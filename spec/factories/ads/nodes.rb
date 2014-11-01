FactoryGirl.define do
  factory :ads_node_banner, class: Ads::Node::Banner, traits: [:cms_node] do
    route "ads/banner"
  end
end
