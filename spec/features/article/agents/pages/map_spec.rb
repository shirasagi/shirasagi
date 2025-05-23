require 'spec_helper'

describe 'article_agents_pages_page', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }

  before do
    Capybara.app_host = "http://#{site.domain}"

    site.map_api = "openlayers"
    site.map_api_layer = "国土地理院地図"
    site.map_api_mypage = "active"
    site.save!
  end

  context "public" do
    context "no markers" do
      let(:item) { create(:article_page, cur_site: site, cur_node: node, layout: layout) }

      it do
        visit item.url
        expect(page).to have_no_css("section.map-page")
      end
    end

    context "show googlemaps link enabled" do
      context "marker name blank" do
        let!(:loc) { [134.589971, 34.067035] }
        let!(:map_point) { {"name" => "", "loc" => loc, "text" => unique_id} }
        let!(:link_name) { "#{loc.to_s}(#{I18n.t("map.links.google_maps_search")})" }
        let(:item) { create(:article_page, cur_site: site, cur_node: node, layout: layout, map_points: [map_point]) }

        it do
          visit item.url
          within "section.map-page" do
            expect(page).to have_css("#map-canvas")
            within ".map-markers" do
              expect(page).to have_selector("a", count: 1)
              expect(page).to have_link link_name
            end
          end
        end
      end

      context "marker name given" do
        let!(:loc) { [134.589971, 34.067035] }
        let!(:map_point) { {"name" => unique_id, "loc" => loc, "text" => unique_id} }
        let!(:link_name) { "#{map_point["name"]}(#{I18n.t("map.links.google_maps_search")})" }
        let(:item) { create(:article_page, cur_site: site, cur_node: node, layout: layout, map_points: [map_point]) }

        it do
          visit item.url
          within "section.map-page" do
            expect(page).to have_css("#map-canvas")
            within ".map-markers" do
              expect(page).to have_selector("a", count: 1)
              expect(page).to have_link link_name
            end
          end
        end
      end
    end

    context "show googlemaps link disabled" do
      let!(:loc) { [134.589971, 34.067035] }
      let!(:map_point) { {"name" => unique_id, "loc" => loc, "text" => unique_id} }
      let(:item) { create(:article_page, cur_site: site, cur_node: node, layout: layout, map_points: [map_point]) }

      before do
        Capybara.app_host = "http://#{site.domain}"

        site.show_google_maps_search = "expired"
        site.update!
      end

      it do
        visit item.url
        within "section.map-page" do
          expect(page).to have_css("#map-canvas")
          expect(page).to have_no_css(".map-markers")
        end
      end
    end
  end
end
