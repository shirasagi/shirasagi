FactoryGirl.define do
  factory :ezine_entry, class: Ezine::Entry do
    cur_site { cms_site }
    email "entry@example.jp"
    email_type "text"
    entry_type "add"
  end
end
