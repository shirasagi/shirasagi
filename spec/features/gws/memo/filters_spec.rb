require 'spec_helper'

describe 'gws_memo_filters', type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let!(:site) { gws_site }
    let!(:folder) { create :gws_memo_folder, cur_site: site }
    let!(:index_path) { gws_memo_filters_path site }

    it do
      login_gws_user to: index_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_error I18n.t("errors.messages.blank")
      expect(page).to have_selector("div#errorExplanation ul li", count: 3)

      name = "name-#{unique_id}"
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[subject]", with: "subject-#{unique_id}"
        select folder.name
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_css('#addon-basic', text: name)

      expect(Gws::Memo::Filter.all.count).to eq 1
      Gws::Memo::Filter.all.first.tap do |item|
        expect(item.site_id).to eq site.id
        expect(item.name).to eq name
        expect(item.subject).to be_present
        expect(item.folder_id).to eq folder.id
      end

      visit index_path
      click_on name
      click_on I18n.t("ss.links.edit")

      name = "modify-#{unique_id}"
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_css('#addon-basic', text: name)

      expect(Gws::Memo::Filter.all.count).to eq 1
      Gws::Memo::Filter.all.first.tap do |item|
        expect(item.site_id).to eq site.id
        expect(item.name).to eq name
        expect(item.subject).to be_present
        expect(item.folder_id).to eq folder.id
      end

      visit index_path
      click_on name
      click_on I18n.t("ss.links.delete")
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Gws::Memo::Filter.all.count).to eq 0
    end
  end
end
