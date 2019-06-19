FactoryBot.define do
  factory :webmail_address_group, class: Webmail::AddressGroup do
    cur_user { ss_user }

    name { "name-#{unique_id}" }
  end
end
