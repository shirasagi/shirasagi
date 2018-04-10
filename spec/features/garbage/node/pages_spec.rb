require 'spec_helper'

describe "garbage_node_pages", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :garbage_node_node }
  let(:item) { create :garbage_node_page, filename: "#{node.filename}/name" }

  let(:index_path) { garbage_nodes_path site.id, node }
  let(:new_path) { new_garbage_node_path site.id, node }
  let(:show_path) { garbage_node_path site.id, node, item }
  let(:edit_path) { edit_garbage_node_path site.id, node, item }
  let(:delete_path) { delete_garbage_node_path site.id, node, item }

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
      expect(page).to have_no_css("form#item-form")
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
