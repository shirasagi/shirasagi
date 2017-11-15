FactoryGirl.define do

  factory :gws_memo_message, class: Gws::Memo::Message do
    cur_site { gws_site }
    cur_user { gws_user }

    subject { "subject-#{unique_id}" }
    text { "text-#{unique_id}" }
    format { 'text' }

    from { { gws_user.id.to_s => 'INBOX.Sent' } }
    member_ids { [gws_user.id] } # => before_validation :set_to
  end
end
