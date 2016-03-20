require 'spec_helper'

describe "gws_roles", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create :gws_role }
  let(:index_path) { gws_roles_path site }
  let(:new_path) { "#{index_path}/new" }
  let(:show_path) { "#{index_path}/#{item.id}" }
  let(:edit_path) { "#{index_path}/#{item.id}/edit" }
  let(:delete_path) { "#{index_path}/#{item.id}/delete" }

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
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
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
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq show_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end
  end
end
