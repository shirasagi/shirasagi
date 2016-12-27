require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create :gws_notice }
  let(:index_path) { gws_notices_path site }
  let(:new_path) { new_gws_notice_path site }
  let(:show_path) { gws_notice_path site.id, item }
  let(:edit_path) { edit_gws_notice_path site, item }
  let(:delete_path) { delete_gws_notice_path site, item }
  let(:public_index_path) { gws_public_notices_path site }
  let(:public_show_path) { gws_public_notice_path site, item }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        fill_in "item[text]", with: "text"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).to eq show_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        fill_in "item[text]", with: "text"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq show_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end

    it "#index" do
      visit public_index_path
      expect(status_code).to eq 200
      expect(current_path).to eq public_index_path
    end

    it "#show" do
      visit public_show_path
      expect(status_code).to eq 200
      expect(current_path).to eq public_show_path
    end
  end
end
