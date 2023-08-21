require 'spec_helper'

describe 'image_map_agents_nodes_page', type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) { create_once :image_map_node_page, filename: "image-map", name: "image-map" }

  let(:usemap) { "image-map-#{node.id}" }
  let(:coords1) { [0, 0, 100, 100] }
  let(:coords2) { [10, 10, 110, 110] }

  let!(:item1) { create(:image_map_page, cur_node: node, coords: coords1, order: 10) }
  let!(:item2) { create(:image_map_page, cur_node: node, coords: coords2, order: 20, state: "closed") }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit item1.url
      within ".image-map-pages" do
        expect(page).to have_css("img[usemap=\"\##{usemap}\"][src=\"#{node.image.url}\"]")
        within "map[name=\"#{usemap}\"]" do
          expect(page).to have_css("area[href=\"\#area-content-1\"][coords=\"#{coords1.join(",")}\"]")
          expect(page).to have_no_css("area[href=\"\#area-content-2\"][coords=\"#{coords2.join(",")}\"]")
        end
      end
    end
  end
end
