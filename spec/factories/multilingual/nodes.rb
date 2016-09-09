FactoryGirl.define do
  factory :multilingual_node_base, class: Multilingual::Node::Base, traits: [:cms_node] do
    route "multilingual/base"
  end

  factory :multilingual_node_lang, class: Multilingual::Node::Lang, traits: [:cms_node] do
    route "multilingual/lang"
  end
end
