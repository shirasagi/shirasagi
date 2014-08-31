FactoryGirl.define do
  factory :event_node_base, class: Event::Node::Base, traits: [:cms_node] do
    route "event/base"
  end

  factory :event_node_page, class: Event::Node::Page, traits: [:cms_node] do
    route "event/page"
  end
end
