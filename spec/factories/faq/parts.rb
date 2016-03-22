FactoryGirl.define do
  factory :faq_part_search, class: Faq::Part::Search, traits: [:cms_part] do
    route "faq/search"
  end
end
