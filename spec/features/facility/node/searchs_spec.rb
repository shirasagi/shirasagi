require 'spec_helper'

describe "facility_node_searches" do
  subject(:site) { cms_site }
  subject(:node) { create_once :facility_node_search, name: "facility" }
  subject(:item) { Cms::Node.last }
  subject(:index_path) { facility_searches_path site.host, node }
  subject(:page_index_path) { facility_pages_path site.host, node }
  subject(:new_path) { new_facility_search_path site.host, node }
  subject(:show_path) { facility_search_path site.host, node, item }
  subject(:edit_path) { edit_facility_search_path site.host, node, item }
  subject(:delete_path) { delete_facility_search_path site.host, node, item }

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
      expect(current_path).to eq page_index_path
    end
  end
end
