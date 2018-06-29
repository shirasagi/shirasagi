FactoryBot.define do
  factory :webmail_filter, class: Webmail::Filter do
    cur_user { ss_user }

    name { "name-#{unique_id}" }
    from { "text-#{unique_id}" }
    action "copy"
    mailbox "INBOX"
  end
end
