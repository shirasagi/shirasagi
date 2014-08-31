FactoryGirl.define do
  factory :category_part_base, class: Category::Part::Base, traits: [:cms_part] do
    route "category/base"
  end

  factory :category_part_node, class: Category::Part::Node, traits: [:cms_part] do
    route "category/node"
  end
end
