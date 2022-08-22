FactoryBot.define do
  factory :webmail_filter, class: Webmail::Filter do
    cur_user { webmail_imap }

    host { cur_user.imap_settings[0][:imap_host] }
    account { cur_user.imap_settings[0][:imap_account] }
    name { "name-#{unique_id}" }
    conjunction { %w(and or).sample }
    conditions do
      Array.new(rand(1..5)) do
        { field: %w(from to cc subject body).sample, operator: %w(include exclude).sample, value: unique_id }
      end
    end
    action { %w(copy move trash delete).sample }
    mailbox { %w(INBOX INBOX.Draft INBOX.Sent INBOX.Trash).sample }
  end
end
