require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:item) { create :cms_page, cur_site: site, basename: unique_id }
  let(:map_api_key) { ENV["GOOGLE_MAPS_API_KEY"] }
  let(:map_center_lng) { rand(12_700..14_500) / 100.0 }
  let(:map_center_lat) { rand(2_700..4_500) / 100.0 }

  before do
    site.map_api = map_api
    site.map_api_layer = map_api_layer
    site.map_api_key = map_api_key
    site.map_center = { "lat" => map_center_lat, "lng" => map_center_lng }
    site.map_max_number_of_markers = 3
    site.save!

    login_cms_user
  end

  shared_examples "map is" do
    describe "only add single marker" do
      let(:marker_lng) { "138.043175" }
      let(:marker_lat) { "36.278482" }
      let(:marker_location) { "#{marker_lng},#{marker_lat}" }
      let(:marker_name) { unique_id }
      let(:marker_text) { Array.new(2) { unique_id } }
      let(:image_path) { "/assets/img/#{map_api.presence || "googlemaps"}/marker#{rand(1..16)}.png" }

      it do
        visit edit_cms_page_path(site: site, id: item)

        within "#item-form" do
          ensure_addon_opened("#addon-map-agents-addons-page")
          within "#addon-map-agents-addons-page" do
            within first(".marker") do
              click_on I18n.t("map.buttons.select_image")
              first(".image [src='#{image_path}']").click

              fill_in "item[map_points][][loc_]", with: marker_location
              fill_in "item[map_points][][name]", with: marker_name
              fill_in "item[map_points][][text]", with: marker_text.join("\n")

              click_on I18n.t("map.buttons.set_marker")
            end
          end

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item.reload

        expect(item.map_points.count).to eq 1
        item.map_points.first.tap do |map_point|
          expect(map_point["name"]).to eq marker_name
          expect(map_point["text"]).to eq marker_text.join("\r\n")
          map_point["loc"].tap do |lng, lat|
            expect(lng).to be_within(0.001).of(marker_lng.to_f)
            expect(lat).to be_within(0.001).of(marker_lat.to_f)
          end
          expect(map_point["image"]).to eq image_path
        end
        expect(item.map_zoom_level).to eq map_zoom_level
        expect(item.center_setting).to eq "auto"
        expect(item.set_center_position).to be_blank
        expect(item.zoom_setting).to eq "auto"
        expect(item.set_zoom_level).to be_blank
      end
    end

    describe "add multiple markers and change settings" do
      let(:marker_lng1) { "138.043175" }
      let(:marker_lat1) { "36.278482" }
      let(:marker_location1) { "#{marker_lng1},#{marker_lat1}" }
      let(:marker_name1) { unique_id }
      let(:marker_text1) { Array.new(2) { unique_id } }

      let(:marker_lng2) { "138.040965" }
      let(:marker_lat2) { "36.008411" }
      let(:marker_location2) { "#{marker_lng2},#{marker_lat2}" }
      let(:marker_name2) { unique_id }
      let(:marker_text2) { Array.new(2) { unique_id } }

      let(:marker_lng3) { "138.023799" }
      let(:marker_lat3) { "36.009521" }
      let(:marker_location3) { "#{marker_lng3},#{marker_lat3}" }
      let(:marker_name3) { unique_id }
      let(:marker_text3) { Array.new(2) { unique_id } }

      it do
        visit edit_cms_page_path(site: site, id: item)

        within "#item-form" do
          ensure_addon_opened("#addon-map-agents-addons-page")
          within "#addon-map-agents-addons-page" do
            within all(".marker").last do
              fill_in "item[map_points][][loc_]", with: marker_location1
              fill_in "item[map_points][][name]", with: marker_name1
              fill_in "item[map_points][][text]", with: marker_text1.join("\n")

              click_on I18n.t("map.buttons.set_marker")
            end

            click_on I18n.t("map.buttons.add_marker")
            within all(".marker").last do
              fill_in "item[map_points][][loc_]", with: marker_location2
              fill_in "item[map_points][][name]", with: marker_name2
              fill_in "item[map_points][][text]", with: marker_text2.join("\n")

              click_on I18n.t("map.buttons.set_marker")
            end

            click_on I18n.t("map.buttons.add_marker")
            within all(".marker").last do
              fill_in "item[map_points][][loc_]", with: marker_location3
              fill_in "item[map_points][][name]", with: marker_name3
              fill_in "item[map_points][][text]", with: marker_text3.join("\n")

              click_on I18n.t("map.buttons.set_marker")
            end

            expect(page).to have_no_css(".add-marker", visible: true)

            # click_on I18n.t("map.designated_location")
            first("[name='item[center_setting]'][value='designated_location']").click
            click_on I18n.t("map.buttons.add_center")

            # click_on I18n.t("map.designated_level")
            first("[name='item[zoom_setting]'][value='designated_level']").click
            click_on I18n.t("map.buttons.add_zoom")
          end

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item.reload

        expect(item.map_points.count).to eq 3
        item.map_points.first.tap do |map_point|
          expect(map_point["name"]).to eq marker_name1
          expect(map_point["text"]).to eq marker_text1.join("\r\n")
          map_point["loc"].tap do |lng, lat|
            expect(lng).to be_within(0.001).of(marker_lng1.to_f)
            expect(lat).to be_within(0.001).of(marker_lat1.to_f)
          end
        end
        expect(item.map_zoom_level).to eq map_zoom_level
        expect(item.center_setting).to eq "designated_location"
        item.set_center_position.split(",").tap do |lng, lat|
          expect(lng.to_f).to be_within(0.001).of(map_center_lng)
          expect(lat.to_f).to be_within(0.001).of(map_center_lat)
        end
        expect(item.zoom_setting).to eq "designated_level"
        expect(item.set_zoom_level).to eq set_zoom_level

        # re-open for edit
        visit edit_cms_page_path(site: site, id: item)
        within "#item-form" do
          ensure_addon_opened("#addon-map-agents-addons-page")
          within "#addon-map-agents-addons-page" do
            # add-marker button is not shown because number of markers reaches the limit
            expect(page).to have_no_css(".add-marker", visible: true)
          end
        end
      end
    end
  end

  context "with google map" do
    let(:map_api) { [ "", "googlemaps" ].sample }
    let(:map_api_layer) { nil }
    let(:map_zoom_level) { rand(8..15) }
    let(:set_zoom_level) { map_zoom_level }

    before do
      @save_googlemaps_zoom_level = SS.config.map.googlemaps_zoom_level
      SS.config.replace_value_at(:map, 'googlemaps_zoom_level', map_zoom_level)
    end

    after do
      SS.config.replace_value_at(:map, 'googlemaps_zoom_level', @save_googlemaps_zoom_level)
    end

    include_context "map is"
  end

  context "with 国土地理院地図 via open layers" do
    let(:map_api) { "openlayers" }
    let(:map_api_layer) { [ nil, "国土地理院地図" ].sample }
    let(:map_zoom_level) { nil }
    let(:set_zoom_level) { rand(8..15) }

    before do
      @save_openlayers_zoom_level = SS.config.map.openlayers_zoom_level
      SS.config.replace_value_at(:map, 'openlayers_zoom_level', set_zoom_level)
    end

    after do
      SS.config.replace_value_at(:map, 'openlayers_zoom_level', @save_openlayers_zoom_level)
    end

    include_context "map is"
  end

  context "with OpenStreetMap via open layers" do
    let(:map_api) { "openlayers" }
    let(:map_api_layer) { "OpenStreetMap" }
    let(:map_zoom_level) { nil }
    let(:set_zoom_level) { SS.config.map.openlayers_zoom_level }

    before do
      @save_openlayers_zoom_level = SS.config.map.openlayers_zoom_level
      SS.config.replace_value_at(:map, 'openlayers_zoom_level', set_zoom_level)
    end

    after do
      SS.config.replace_value_at(:map, 'openlayers_zoom_level', @save_openlayers_zoom_level)
    end

    include_context "map is"
  end

  context "when disable_mypage is set to true" do
    let(:map_api) { [ "", "googlemaps", "openlayers" ].sample }
    let(:map_api_layer) { [ nil, "国土地理院地図", "OpenStreetMap" ].sample }
    let(:marker_lng) { "138.043175" }
    let(:marker_lat) { "36.278482" }
    let(:marker_location) { "#{marker_lng},#{marker_lat}" }
    let(:marker_name) { unique_id }
    let(:marker_text) { Array.new(2) { unique_id } }

    before do
      @save_disable_mypage = SS.config.map.disable_mypage
      SS.config.replace_value_at(:map, 'disable_mypage', true)
    end

    after do
      SS.config.replace_value_at(:map, 'disable_mypage', @save_disable_mypage)
    end

    it do
      visit edit_cms_page_path(site: site, id: item)

      within "#item-form" do
        ensure_addon_opened("#addon-map-agents-addons-page")
        within "#addon-map-agents-addons-page" do
          within first(".marker") do
            fill_in "item[map_points][][loc_]", with: marker_location
            fill_in "item[map_points][][name]", with: marker_name
            fill_in "item[map_points][][text]", with: marker_text.join("\n")

            click_on I18n.t("map.buttons.set_marker")
          end
        end

        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item.reload

      expect(item.map_points.count).to eq 1
      item.map_points.first.tap do |map_point|
        expect(map_point["name"]).to eq marker_name
        expect(map_point["text"]).to eq marker_text.join("\r\n")
        map_point["loc"].tap do |lng, lat|
          expect(lng).to be_within(0.001).of(marker_lng.to_f)
          expect(lat).to be_within(0.001).of(marker_lat.to_f)
        end
      end
      if map_api == "openlayers"
        expect(item.map_zoom_level).to be_blank
      else
        expect(item.map_zoom_level).to eq 13
      end
      expect(item.center_setting).to eq "auto"
      expect(item.set_center_position).to be_blank
      expect(item.zoom_setting).to eq "auto"
      expect(item.set_zoom_level).to be_blank
    end
  end
end
