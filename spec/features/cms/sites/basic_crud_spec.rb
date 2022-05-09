require 'spec_helper'

describe "cms_sites", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:index_path) { cms_site_path site.id }

  before { login_cms_user }

  context "basic crud" do
    it do
      visit index_path
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      site.reload
      expect(site.name).to eq "modify"
    end
  end

  context "addon-ss-agents-addons-map_setting" do
    let(:map_api) { %w(googlemaps openlayers).sample }
    let(:map_api_label) { I18n.t("ss.options.map_api.#{map_api}") }
    let(:map_api_key) { unique_id }
    let(:map_api_layer) { SS.config.map.layers.map { |layer| layer["name"] }.sample }
    let(:map_api_layer_label) { map_api_layer }
    let(:show_google_maps_search) { %w(active expired).sample }
    let(:show_google_maps_search_label) { I18n.t("ss.options.state.#{show_google_maps_search}") }
    let(:map_api_mypage) { %w(active expired).sample }
    let(:map_api_mypage_label) { I18n.t("ss.options.state.#{map_api_mypage}") }

    it do
      visit index_path
      click_on I18n.t("ss.links.edit")

      ensure_addon_opened("#addon-ss-agents-addons-map_setting")
      within "form#item-form" do
        select map_api_label, from: "item[map_api]"
        fill_in "item[map_api_key]", with: map_api_key
        select map_api_layer_label, from: "item[map_api_layer]"
        select show_google_maps_search_label, from: "item[show_google_maps_search]"
        select map_api_mypage_label, from: "item[map_api_mypage]"

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      site.reload
      expect(site.map_api).to eq map_api
      expect(site.map_api_key).to eq map_api_key
      expect(site.map_api_layer).to eq map_api_layer
      expect(site.show_google_maps_search).to eq show_google_maps_search
      expect(site.map_api_mypage).to eq map_api_mypage
    end
  end
end
