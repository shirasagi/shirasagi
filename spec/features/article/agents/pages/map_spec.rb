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

    context "show googlemaps link in view with hide" do
      let!(:loc) { [134.589971, 34.067035] }
      let!(:map_point) { {"name" => unique_id, "loc" => loc, "text" => unique_id} }
      let(:item) { create(:article_page, cur_site: site, cur_node: node, layout: layout, map_points: [map_point]) }

      before do
        Capybara.app_host = "http://#{site.domain}"
      end

      it do
        visit item.url
        within "section.map-page" do
          expect(page).to have_css("h2", text: I18n.t("map.views.header"))
          expect(page).to have_css("#map-canvas")
          expect(page).to have_no_css(".map-markers")
        end
      end

      it do
        site.show_google_maps_search_in_view = "hide"
        site.update!

        visit item.url
        within "section.map-page" do
          expect(page).to have_css("h2", text: I18n.t("map.views.header"))
          expect(page).to have_css("#map-canvas")
          expect(page).to have_no_css(".map-markers")
        end
      end
    end

    context "show googlemaps link in view with show_all" do
      context "marker name blank" do
        let!(:loc1) { [134.589971, 34.067035] }
        let!(:loc2) { [134.589960, 34.067015] }
        let!(:map_point1) { {"name" => "", "loc" => loc1, "text" => unique_id} }
        let!(:map_point2) { {"name" => "", "loc" => loc2, "text" => unique_id} }
        let!(:link_name1) { "#{loc1}(#{I18n.t("map.links.google_maps_search")})" }
        let!(:link_name2) { "#{loc2}(#{I18n.t("map.links.google_maps_search")})" }
        let(:item) do
          create(:article_page, cur_site: site, cur_node: node, layout: layout, map_points: [map_point1, map_point2])
        end

        it do
          site.show_google_maps_search_in_view = "show_all"
          site.update!

          visit item.url
          within "section.map-page" do
            expect(page).to have_css("h2", text: I18n.t("map.views.header"))
            expect(page).to have_css("#map-canvas")
            within ".map-markers" do
              expect(page).to have_selector("a", count: 2)
              expect(page).to have_link link_name1
              expect(page).to have_link link_name2
            end
          end
        end
      end

      context "marker name given" do
        let!(:loc1) { [134.589971, 34.067035] }
        let!(:loc2) { [134.589960, 34.067015] }
        let!(:map_point1) { {"name" => unique_id, "loc" => loc1, "text" => unique_id} }
        let!(:map_point2) { {"name" => unique_id, "loc" => loc2, "text" => unique_id} }
        let!(:link_name1) { "#{map_point1["name"]}(#{I18n.t("map.links.google_maps_search")})" }
        let!(:link_name2) { "#{map_point2["name"]}(#{I18n.t("map.links.google_maps_search")})" }
        let(:item) do
          create(:article_page, cur_site: site, cur_node: node, layout: layout, map_points: [map_point1, map_point2])
        end

        it do
          site.show_google_maps_search_in_view = "show_all"
          site.update!

          visit item.url
          within "section.map-page" do
            expect(page).to have_css("h2", text: I18n.t("map.views.header"))
            expect(page).to have_css("#map-canvas")
            within ".map-markers" do
              expect(page).to have_selector("a", count: 2)
              expect(page).to have_link link_name1
              expect(page).to have_link link_name2
            end
          end
        end
      end
    end

    context "show googlemaps link in view with show_first" do
      context "marker name blank" do
        let!(:loc1) { [134.589971, 34.067035] }
        let!(:loc2) { [134.589960, 34.067015] }
        let!(:map_point1) { {"name" => "", "loc" => loc1, "text" => unique_id} }
        let!(:map_point2) { {"name" => "", "loc" => loc2, "text" => unique_id} }
        let!(:link_name1) { "#{loc1}(#{I18n.t("map.links.google_maps_search")})" }
        let!(:link_name2) { "#{loc2}(#{I18n.t("map.links.google_maps_search")})" }
        let(:item) do
          create(:article_page, cur_site: site, cur_node: node, layout: layout, map_points: [map_point1, map_point2])
        end

        it do
          site.show_google_maps_search_in_view = "show_first"
          site.update!

          visit item.url
          within "section.map-page" do
            expect(page).to have_css("h2", text: I18n.t("map.views.header"))
            expect(page).to have_css("#map-canvas")
            within ".map-markers" do
              expect(page).to have_selector("a", count: 1)
              expect(page).to have_link link_name1
              expect(page).to have_no_link link_name2
            end
          end
        end
      end

      context "marker name given" do
        let!(:loc1) { [134.589971, 34.067035] }
        let!(:loc2) { [134.589960, 34.067015] }
        let!(:map_point1) { {"name" => unique_id, "loc" => loc1, "text" => unique_id} }
        let!(:map_point2) { {"name" => unique_id, "loc" => loc2, "text" => unique_id} }
        let!(:link_name1) { "#{map_point1["name"]}(#{I18n.t("map.links.google_maps_search")})" }
        let!(:link_name2) { "#{map_point2["name"]}(#{I18n.t("map.links.google_maps_search")})" }
        let(:item) do
          create(:article_page, cur_site: site, cur_node: node, layout: layout, map_points: [map_point1, map_point2])
        end

        it do
          site.show_google_maps_search_in_view = "show_first"
          site.update!

          visit item.url
          within "section.map-page" do
            expect(page).to have_css("h2", text: I18n.t("map.views.header"))
            expect(page).to have_css("#map-canvas")
            within ".map-markers" do
              expect(page).to have_selector("a", count: 1)
              expect(page).to have_link link_name1
              expect(page).to have_no_link link_name2
            end
          end
        end
      end
    end

    context "modify header text" do
      let!(:loc) { [134.589971, 34.067035] }
      let!(:map_point) { {"name" => unique_id, "loc" => loc, "text" => unique_id} }
      let!(:header_text) { unique_id }
      let!(:link_name) { "#{map_point["name"]}(#{I18n.t("map.links.google_maps_search")})" }
      let(:item) { create(:article_page, cur_site: site, cur_node: node, layout: layout, map_points: [map_point]) }

      before do
        Capybara.app_host = "http://#{site.domain}"

        site.map_header_text = header_text
        site.update!
      end

      it do
        visit item.url
        within "section.map-page" do
          expect(page).to have_css("h2", text: header_text)
          expect(page).to have_css("#map-canvas")
        end
      end
    end
  end
end
