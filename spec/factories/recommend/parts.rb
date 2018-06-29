FactoryBot.define do
  factory :recommend_part_history, class: Recommend::Part::History, traits: [:cms_part] do
    route "recommend/history"
  end

  factory :recommend_part_similarity, class: Recommend::Part::Similarity, traits: [:cms_part] do
    route "recommend/similarity"
  end
end
