require 'spec_helper'

describe "gws_search_form_targets", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:item) { create(:gws_search_form_target) }
  let(:index_path) { gws_search_form_targets_path site.id }
  let(:new_path) { new_gws_search_form_target_path site.id }
  let(:show_path) { gws_search_form_target_path site.id, item }
  let(:edit_path) { edit_gws_search_form_target_path site.id, item }
  let(:delete_path) { delete_gws_search_form_target_path site.id, item }

  let(:name) { unique_id }
  let(:place_holder) { unique_id }
  let(:search_url) { "https://search.example.jp" }
  let(:keyword_name) { "q" }
  let(:other_query) { "num=20" }

  context "basic crud" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[place_holder]", with: place_holder
        select I18n.t("gws/search_form.options.search_service.external"), from: "item[search_service]"
        fill_in "item[search_url]", with: search_url
        fill_in "item[search_keyword_name]", with: keyword_name
        fill_in "item[search_other_query]", with: other_query
        select I18n.t("ss.options.state.enabled"), from: "item[state]"
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-basic" do
        expect(page).to have_css("dd", text: name)
        expect(page).to have_css("dd", text: place_holder)
        expect(page).to have_css("dd", text: search_url)
        expect(page).to have_css("dd", text: keyword_name)
        expect(page).to have_css("dd", text: other_query)
      end
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
    end

    it "#delete" do
      visit delete_path
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')
    end
  end
end
