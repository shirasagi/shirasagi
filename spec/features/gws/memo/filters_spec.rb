require 'spec_helper'

describe 'gws_memo_filters', type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let!(:site) { gws_site }
    let!(:item) { create :gws_memo_filter }
    let!(:folder) { create :gws_memo_folder }
    let!(:index_path) { gws_memo_filters_path site }
    let!(:new_path) { new_gws_memo_filter_path site }
    let!(:show_path) { gws_memo_filter_path site, item }
    let!(:edit_path) { edit_gws_memo_filter_path site, item }
    let!(:delete_path) { delete_gws_memo_filter_path site, item }

    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path

      name = "name-#{unique_id}"
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[subject]", with: "subject-#{unique_id}"
        select folder.name
        click_button "保存"
      end
      expect(first('#addon-basic')).to have_text(name)
    end

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path

      name = "modify-#{unique_id}"
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_button "保存"
      end
      expect(first('#addon-basic')).to have_text(name)
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end
  end
end
