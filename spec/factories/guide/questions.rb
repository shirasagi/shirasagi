FactoryBot.define do
  factory :guide_question, class: Guide::Question do
    name { unique_id }
    id_name { unique_id }
    question_type { "yes_no" }
  end
end
