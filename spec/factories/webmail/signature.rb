FactoryBot.define do
  factory :webmail_signature, class: Webmail::Signature do
    cur_user { ss_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
  end
end
