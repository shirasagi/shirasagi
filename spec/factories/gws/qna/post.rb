FactoryBot.define do
  factory :gws_qna_post, class: Gws::Qna::Post do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }

    factory :gws_qna_comment do
      association :parent, factory: :gws_qna_topic
    end

    factory :gws_qna_comment_to_comment do
      association :parent, factory: :gws_qna_comment
    end
  end
end
