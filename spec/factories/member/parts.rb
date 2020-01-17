FactoryBot.define do
  factory :member_part_login, class: Member::Part::Login, traits: [:cms_part] do
    ajax_view 'enabled'
    route "member/login"
  end
end
