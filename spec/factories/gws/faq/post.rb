FactoryBot.define do
  factory :gws_faq_post, class: Gws::Faq::Post do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }

    factory :gws_faq_comment do
      association :parent, factory: :gws_faq_topic
    end

    factory :gws_faq_comment_to_comment do
      association :parent, factory: :gws_faq_comment
    end
  end
end
