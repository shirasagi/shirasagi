require 'spec_helper'

describe 'article_agents_pages_page', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
  let!(:loc) { [134.589971, 34.067035] }
  let!(:map_point) { { "name" => unique_id, "loc" => loc, "text" => unique_id } }
  let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout: layout, map_points: [map_point]) }
  let(:search_end_point) { SS.config.map.googlemaps_search_end_point }

  before do
    site.map_api = "openlayers"
    site.map_api_layer = "国土地理院地図"
    site.show_google_maps_search_in_marker = "show"
    site.save!
  end

  shared_examples "map config is exported to public page" do
    it do
      within "section.map-page" do
        expect(page).to have_css("#map-canvas")
      end

      expect(page.evaluate_script("SS.config.map.googlemaps_search_end_point")).to eq search_end_point
      expect(page.evaluate_script("SS.config.map.openlayers_zoom_level")).to eq SS.config.map.openlayers_zoom_level
      expect(page.evaluate_script("SS.config.map.api_key")).to be_nil
      expect(page.evaluate_script("Googlemaps_Map.mapsSearchUrl()")).to eq search_end_point

      html = page.evaluate_script("Googlemaps_Map.getMapsSearchHtml(#{loc[1]}, #{loc[0]})")
      expect(html).to include("#{search_end_point}#{loc[1]},#{loc[0]}")
      expect(html).to include(I18n.t("map.links.google_maps_search"))

      # マーカー描画時に Googlemaps_Map.getMapsSearchHtml が呼ばれるので、JS エラーが発生していないことを確認
      expect(capture_console_logs).to all(satisfy { |log| !log.include?("Uncaught") })
    end
  end

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
      visit item.url
    end

    it_behaves_like "map config is exported to public page"
  end

  context "preview" do
    before do
      login_cms_user
      visit cms_preview_path(site: site, path: item.preview_path)
    end

    it_behaves_like "map config is exported to public page"
  end
end
