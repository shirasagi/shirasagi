FactoryGirl.define do

  factory :gws_memo_message, class: Gws::Memo::Message do
    cur_site { gws_site }
    cur_user { gws_user }

    subject { "subject-#{unique_id}" }
    text { "text-#{unique_id}" }
    format { 'text' }

    path { { gws_user.id.to_s => 'INBOX.Sent' } }
    to_member_ids { [gws_user.id] }

    send_date { Time.zone.now }
  end
end
