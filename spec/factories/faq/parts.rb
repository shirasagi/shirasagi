FactoryGirl.define do
  factory :faq_part_search, class: Article::Part::Page, traits: [:cms_part] do
    route "faq/search"
  end
end
