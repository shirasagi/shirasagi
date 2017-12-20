require 'spec_helper'

describe "cms_roles" do
  subject(:site) { cms_site }
  subject(:item) { Cms::Role.last }
  subject(:index_path) { cms_roles_path site.id }
  subject(:new_path) { new_cms_role_path site.id }
  subject(:show_path) { cms_role_path site.id, item }
  subject(:edit_path) { edit_cms_role_path site.id, item }
  subject(:delete_path) { delete_cms_role_path site.id, item }
  subject(:import_path) { import_cms_roles_path site.id, item }

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
        #check "item[permissions][]"
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

    it "#import" do
      visit import_path
      within "form" do
        attach_file "item[file]", "#{Rails.root}/spec/fixtures/cms/role/cms_roles_1.csv"
        click_button "インポート"
      end
      expect(status_code).to eq 200
    end
  end
end
