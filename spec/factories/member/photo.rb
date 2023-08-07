FactoryBot.define do
  factory :member_photo, class: Member::Photo, traits: [:cms_page] do
    route { "member/photo" }
    listable_state { "public" }
    slideable_state { "public" }
    in_image { Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/ss/logo.png") }
    map_points { [] }
    map_zoom_level { 13 }
    caption { "caption" }
    license_name { "free" }
  end

  trait :member_photo_with_map_points do
    map_points { [{ "loc" => [134.559257, 34.065750] }] }
  end
end
