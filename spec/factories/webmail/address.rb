FactoryGirl.define do
  factory :webmail_address, class: Webmail::Address do
    cur_user { ss_user }

    name { "name-#{unique_id}" }
    email { "#{unique_id}@example.jp" }
  end
end
