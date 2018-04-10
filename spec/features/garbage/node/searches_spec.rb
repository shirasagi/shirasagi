require 'spec_helper'

describe "garbage_node_searches", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:item) { create :garbage_node_search }

  let(:index_path) { garbage_searches_path site.id, item }
  let(:new_path) { new_garbage_search_path site.id, item }

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
      expect(page).to have_no_css("form#item-form")
    end
  end
end
