FactoryBot.define do
  factory :chat_intent, class: Chat::Intent do
    cur_site { cms_site }
    cur_user { cms_user }
    name { unique_id.to_s }
    phrase { unique_id.to_s }
    response { "<p>#{unique_id}</p>" }
  end
end
