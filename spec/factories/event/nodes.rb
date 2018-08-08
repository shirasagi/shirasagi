FactoryBot.define do
  factory :event_node_base, class: Event::Node::Base, traits: [:cms_node] do
    route "event/base"
  end

  factory :event_node_page, class: Event::Node::Page, traits: [:cms_node] do
    route "event/page"
  end

  factory :event_node_search, class: Event::Node::Search, traits: [:cms_node] do
    route "event/search"
  end

  factory :event_node_ical, class: Event::Node::Ical, traits: [:cms_node] do
    route "event/ical"
  end
end
