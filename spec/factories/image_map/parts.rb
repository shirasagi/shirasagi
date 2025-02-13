FactoryBot.define do
  factory :image_map_part_page, class: ImageMap::Part::Page, traits: [:cms_part] do
    route { "image_map/page" }
    cur_node { create :image_map_node_page, cur_site: cur_site }
  end
end
