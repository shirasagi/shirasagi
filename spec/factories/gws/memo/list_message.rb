FactoryBot.define do
  factory :gws_memo_list_message, class: Gws::Memo::ListMessage do
    cur_site { gws_site }
    cur_user { gws_user }

    subject { "subject-#{unique_id}" }
    text { "text-#{unique_id}" }
    format { 'text' }

    from_member_name { list ? list.name : nil }
    member_ids { list ? list.overall_members.pluck(:id) : nil }

    send_date { Time.zone.now }

    trait :with_draft do
      state { 'closed' }
    end
  end
end
