FactoryBot.define do
  factory :gws_memo_message, class: Gws::Memo::Message do
    cur_site { gws_site }
    cur_user { gws_user }

    subject { "subject-#{unique_id}" }
    text { "text-#{unique_id}" }
    format { 'text' }

    user_settings { [{ 'user_id' => gws_user.id, 'path' => 'INBOX.Sent' }] }
    in_to_members { [gws_user.id.to_s] }

    send_date { Time.zone.now }

    trait :with_draft do
      state { 'closed' }
    end
  end
end
