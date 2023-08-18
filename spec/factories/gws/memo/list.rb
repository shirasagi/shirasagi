FactoryBot.define do
  factory :gws_memo_list, class: Gws::Memo::List do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    sender_name { ss_japanese_text }
    signature { [ "-" * 8, ss_japanese_text, ss_japanese_text ].join("\n") }
    member_ids { [gws_user.id] }
  end
end
