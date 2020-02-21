FactoryBot.define do
  factory :member_group, class: Member::Group do
    site { cms_site }
    name { unique_id.to_s }
    invitation_message { unique_id.to_s }
  end
end
