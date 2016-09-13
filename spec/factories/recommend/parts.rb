FactoryGirl.define do
  factory :recommend_part_history, class: Recommend::Part::History, traits: [:cms_part] do
    route "recommend/history"
  end
end
