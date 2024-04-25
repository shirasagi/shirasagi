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

  context "addon-cms-agents-addons-page_setting" do
    let(:auto_keywords) { %w(enabled disabled).sample }
    let(:auto_keywords_label) { I18n.t("ss.options.state.#{auto_keywords}") }
    let(:keywords) { Array.new(2) { unique_id } }
    let(:auto_description) { %w(enabled disabled).sample }
    let(:auto_description_label) { I18n.t("ss.options.state.#{auto_description}") }
    let(:max_name_length) { [ 80, 0 ].sample }
    let(:max_name_length_label) { I18n.t("cms.options.max_name_length.#{max_name_length}") }
    let(:page_expiration_state) { %w(enabled disabled).sample }
    let(:page_expiration_state_label) { I18n.t("ss.options.state.#{page_expiration_state}") }
    let(:page_expiration_before) { %w(90.days 180.days 1.year 2.years 3.years).sample }
    let(:page_expiration_before_label) do
      I18n.t("cms.options.page_expiration_before.#{page_expiration_before.sub(".", "_")}")
    end
    let(:page_expiration_mail_subject) { unique_id }
    let(:page_expiration_mail_upper_text) { Array.new(2) { unique_id } }

    it do
      visit index_path
      click_on I18n.t("ss.links.edit")

      ensure_addon_opened("#addon-cms-agents-addons-page_setting")
      within "form#item-form" do
        select auto_keywords_label, from: "item[auto_keywords]"
        fill_in "item[keywords]", with: keywords.join(" ")
        select auto_description_label, from: "item[auto_description]"
        select max_name_length_label, from: "item[max_name_length]"
        select page_expiration_state_label, from: "item[page_expiration_state]"
        select page_expiration_before_label, from: "item[page_expiration_before]"
        fill_in "item[page_expiration_mail_subject]", with: page_expiration_mail_subject
        fill_in "item[page_expiration_mail_upper_text]", with: page_expiration_mail_upper_text.join("\n")

        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      site.reload
      expect(site.auto_keywords).to eq auto_keywords
      expect(site.keywords).to eq keywords
      expect(site.auto_description).to eq auto_description
      expect(site.max_name_length).to eq max_name_length
      expect(site.page_expiration_state).to eq page_expiration_state
      expect(site.page_expiration_before).to eq page_expiration_before
      expect(site.page_expiration_mail_subject).to eq page_expiration_mail_subject
      expect(site.page_expiration_mail_upper_text).to eq page_expiration_mail_upper_text.join("\r\n")
    end
  end

  context "addon-ss-agents-addons-approve_setting" do
    let(:forced_update) { %w(enabled disabled).sample }
    let(:forced_update_label) { I18n.t("ss.options.state.#{forced_update}") }
    let(:close_confirmation) { %w(enabled disabled).sample }
    let(:close_confirmation_label) { I18n.t("ss.options.state.#{close_confirmation}") }
    let(:approve_remind_state) { %w(enabled disabled).sample }
    let(:approve_remind_state_label) { I18n.t("ss.options.state.#{approve_remind_state}") }
    let(:approve_remind_later) { %w(1.day 2.days 3.days 4.days 5.days 6.days 1.week 2.weeks).sample }
    let(:approve_remind_later_label) { I18n.t("ss.options.approve_remind_later.#{approve_remind_later.sub('.', '_')}") }

    it do
      visit index_path
      click_on I18n.t("ss.links.edit")

      ensure_addon_opened("#addon-ss-agents-addons-approve_setting")
      within "form#item-form" do
        select forced_update_label, from: "item[forced_update]"
        select close_confirmation_label, from: "item[close_confirmation]"
        select approve_remind_state_label, from: "item[approve_remind_state]"
        select approve_remind_later_label, from: "item[approve_remind_later]"

        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      site.reload
      expect(site.forced_update).to eq forced_update
      expect(site.close_confirmation).to eq close_confirmation
      expect(site.approve_remind_state).to eq approve_remind_state
      expect(site.approve_remind_later).to eq approve_remind_later
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
    let(:map_center_lng) { rand(13_800..13_900) / 100.0 }
    let(:map_center_lat) { rand(3600..3700) / 100.0 }
    let(:map_max_number_of_markers) { rand(1..20) }

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
        fill_in "item[map_center][lng]", with: map_center_lng
        fill_in "item[map_center][lat]", with: map_center_lat
        fill_in "item[map_max_number_of_markers]", with: map_max_number_of_markers

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      site.reload
      expect(site.map_api).to eq map_api
      expect(site.map_api_key).to eq map_api_key
      expect(site.map_api_layer).to eq map_api_layer
      expect(site.show_google_maps_search).to eq show_google_maps_search
      expect(site.map_api_mypage).to eq map_api_mypage
      expect(site.map_center.lng).to be_within(0.1).of(map_center_lng)
      expect(site.map_center.lat).to be_within(0.1).of(map_center_lat)
      expect(site.map_max_number_of_markers).to eq map_max_number_of_markers
    end
  end
end
