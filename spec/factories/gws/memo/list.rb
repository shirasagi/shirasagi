FactoryGirl.define do
  factory :gws_memo_list, class: Gws::Memo::List do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    member_ids { [gws_user.id] }
  end
end
