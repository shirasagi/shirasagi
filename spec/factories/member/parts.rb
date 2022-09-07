FactoryBot.define do
  factory :member_part_login, class: Member::Part::Login, traits: [:cms_part] do
    route { "member/login" }
  end

  factory :member_part_photo_search, class: Member::Part::PhotoSearch, traits: [:cms_part] do
    route { "member/photo_search" }
  end
end
