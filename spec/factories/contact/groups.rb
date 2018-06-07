FactoryBot.define do
  factory :contact_group, class: Cms::Group do
    name "contact_group"
    contact_tel "0000000000"
    contact_fax "1111111111"
    contact_email "contact@example.jp"
    contact_link_url "http://example.jp"
    contact_link_name "link_name"
  end
end
