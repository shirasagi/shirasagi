FactoryBot.define do
  factory :member_photo_spot, class: Member::PhotoSpot, traits: [:cms_page] do
    route { "member/photo_spot" }

    after(:build) do |item|
      item.member_photo_ids = [create(:member_photo, :member_photo_with_map_points).id]
    end
  end
end
