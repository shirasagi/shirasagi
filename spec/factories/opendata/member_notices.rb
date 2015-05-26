FactoryGirl.define do
  factory :opendata_member_notice, class: Opendata::MemberNotice do
    transient do
      site nil
      member nil
    end

    site_id { site.present? ? site.id : cms_site.id }
    member_id { member.present? ? member.id : nil }
    commented_count 11
    confirmed { Time.zone.now }
  end
end
