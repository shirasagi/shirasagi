FactoryBot.define do
  factory :recommend_similarity_score, class: Recommend::SimilarityScore do
    cur_site { cms_site }
  end
end