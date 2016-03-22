FactoryGirl.define do
  factory :ezine_entry, class: Ezine::Entry do
    site_id { cms_site.id }
    email "entry@example.jp"
    email_type "text"
    entry_type "add"
  end
end
