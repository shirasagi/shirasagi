FactoryBot.define do
  factory :member_part_login, class: Member::Part::Login, traits: [:cms_part] do
    route "member/login"
  end
end
