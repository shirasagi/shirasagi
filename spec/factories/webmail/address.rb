FactoryBot.define do
  factory :webmail_address, class: Webmail::Address do
    cur_user { ss_user }

    name { "name-#{unique_id}" }
    kana { "kana-#{unique_id}" }
    email { "email-#{unique_id}@example.jp" }
  end
end
