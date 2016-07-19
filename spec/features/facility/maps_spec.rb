require 'spec_helper'

describe "facility_maps" do
  subject(:site) { cms_site }
  subject(:node) { create_once :facility_node_page, name: "facility" }
  subject(:item) { Facility::Map.last }
  subject(:index_path) { facility_maps_path site.id, node }
  subject(:new_path) { new_facility_map_path site.id, node }
  subject(:show_path) { facility_map_path site.id, node, item }
  subject(:edit_path) { edit_facility_map_path site.id, node, item }
  subject(:delete_path) { delete_facility_map_path site.id, node, item }
  let(:addon_titles) { page.all("form .addon-head h2").map(&:text).sort }
  let(:expected_addon_titles) { %w(メタ情報 公開予約 公開設定 地図 基本情報 承認 権限).sort }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      expect(addon_titles).to eq expected_addon_titles
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).not_to have_css("form#item-form")
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
