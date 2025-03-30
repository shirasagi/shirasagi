require 'spec_helper'

describe "gws_bookmark_items", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:item) { create :gws_bookmark_item }
  let(:folder) { user.bookmark_root_folder(site) }

  let(:index_path) { gws_bookmark_main_path site }
  let(:show_path) { gws_bookmark_item_path site, item }
  let(:edit_path) { edit_gws_bookmark_item_path site, item }
  let(:delete_path) { delete_gws_bookmark_item_path site, item }

  let(:name) { unique_id }
  let(:url) { "https://sample.example.jp" }
  let(:order) { 20 }

  before { login_gws_user }

  context "basic crud" do
    it "#index" do
      visit index_path

      expect(current_path).not_to eq sns_login_path
      expect(folder.name).to eq Gws::Bookmark::Folder.default_root_name

      within "#content-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end
    end

    it "#new" do
      visit index_path

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in 'item[name]', with: name
        fill_in 'item[url]', with: url
        select I18n.t("ss.options.link_target._blank"), from: 'item[link_target]'
        select I18n.t("gws/bookmark.options.bookmark_model.other"), from: 'item[bookmark_model]'
        fill_in 'item[order]', with: order
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-basic" do
        expect(page).to have_css("dd", text: name)
        expect(page).to have_css("dd", text: url)
        expect(page).to have_css("dd", text: I18n.t("gws/bookmark.options.bookmark_model.other"))
        expect(page).to have_css("dd", text: order)
        expect(page).to have_css("dd", text: folder.name)
      end
    end

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path

      within "#addon-basic" do
        expect(page).to have_css("dd", text: folder.name)
      end
    end

    it "#edit" do
      visit edit_path

      within "form#item-form" do
        fill_in 'item[name]', with: name
        fill_in 'item[url]', with: url
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-basic" do
        expect(page).to have_css("dd", text: name)
        expect(page).to have_css("dd", text: url)
        expect(page).to have_css("dd", text: folder.name)
      end
    end

    it "#delete" do
      visit delete_path
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')
    end
  end
end
