FactoryBot.define do
  factory :image_map_part_page, class: ImageMap::Part::Page, traits: [:cms_part] do
    route { "image_map/page" }
  end
end
