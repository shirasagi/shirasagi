require 'spec_helper'

describe "cms_apis_node_temp_files" do
  let(:site) { cms_site }
  let(:item) { Cms::TempFile.last }
  let(:node) { create :cms_node }
  let(:index_path) { cms_apis_node_temp_files_path site.id, node.id }
  let(:new_path) { new_cms_apis_node_temp_file_path site.id, node.id }
  let(:show_path) { cms_apis_node_temp_file_path site.id, node.id, item }
  let(:edit_path) { edit_cms_apis_node_temp_file_path site.id, node.id, item }
  let(:delete_path) { delete_cms_apis_node_temp_file_path site.id, node.id, item }
  let(:select_path) { select_cms_apis_node_temp_file_path site.id, node.id, item }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "#ajax-form" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
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

    it "#select" do
      visit select_path
      expect(status_code).to eq 200
    end

    it "#edit" do
      visit edit_path
      within "#ajax-form" do
        fill_in "item[filename]", with: "modify"
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
