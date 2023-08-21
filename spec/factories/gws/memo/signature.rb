FactoryBot.define do

  factory :gws_memo_signature, class: Gws::Memo::Signature do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
    default { 'disabled' }
  end
end
