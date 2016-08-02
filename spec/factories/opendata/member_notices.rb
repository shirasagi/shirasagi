FactoryGirl.define do
  factory :opendata_member_notice, class: Opendata::MemberNotice do
    site_id { cms_site.id }
    commented_count 11
    confirmed { Time.zone.now }
  end
end
