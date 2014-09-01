FactoryGirl.define do
  factory :cms_member, class: Cms::Member do
    site_id { create(:ss_site).id }
    name "#{unique_id}"
    email "#{unique_id}@example.jp"
    in_password "pass"
  end
end
