FactoryBot.define do
  factory :image_map_page, class: ImageMap::Page, traits: [:cms_page] do
    cur_site { cms_site }
    filename { unique_id }
    route { "image_map/page" }
    coords { [0, 100, 100, 200] }
  end
end
