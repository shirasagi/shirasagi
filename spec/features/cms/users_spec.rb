# coding: utf-8
require 'spec_helper'

describe "cms_users" do
  subject(:item) { Cms::User.last }
  subject(:index_path) { "/.#{cms_site.host}/cms/users" }
  subject(:new_path) { "#{index_path}/new" }
  subject(:show_path) { "#{index_path}/#{item.id}" }
  subject(:edit_path) { "#{show_path}/edit" }
  subject(:delete_path) { "#{show_path}/delete" }

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
        fill_in "item[email]", with: "cms_sample@example.jp"
        fill_in "item[in_password]", with: "pass"
        check "item[group_ids][]"
        check "item[cms_role_ids][]"
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
      expect(current_path).to eq index_path
    end
  end
end
