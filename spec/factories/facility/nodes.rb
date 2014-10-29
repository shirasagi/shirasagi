FactoryGirl.define do
  factory :facility_node_base, class: Facility::Node::Base, traits: [:cms_node] do
    route "facility/base"
  end

  factory :facility_node_node, class: Facility::Node::Node, traits: [:cms_node] do
    route "facility/node"
  end

  factory :facility_node_page, class: Facility::Node::Page, traits: [:cms_node] do
    route "facility/page"
  end

  factory :facility_node_search, class: Facility::Node::Search, traits: [:cms_node] do
    route "facility/search"
  end

  factory :facility_node_category, class: Facility::Node::Category, traits: [:cms_node] do
    route "facility/category"
  end

  factory :facility_node_feature, class: Facility::Node::Feature, traits: [:cms_node] do
    route "facility/feature"
  end

  factory :facility_node_location, class: Facility::Node::Location, traits: [:cms_node] do
    route "facility/location"
  end
end
