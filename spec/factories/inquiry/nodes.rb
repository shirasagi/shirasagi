FactoryGirl.define do
  factory :inquiry_node_base, class: Inquiry::Node::Base, traits: [:cms_node] do
    route "inquiry/base"
  end

  factory :inquiry_node_form, class: Inquiry::Node::Form, traits: [:cms_node] do
    route "inquiry/form"
  end
end
