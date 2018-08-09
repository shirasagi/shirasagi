require 'spec_helper'

describe "member_photos", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :member_node_photo, filename: "photos", name: "photos" }
  let(:item) { create(:member_photo, cur_node: node) }
  let(:index_path) { member_photos_path site.id, node }
  let(:new_path) { new_member_photo_path site.id, node }
  let(:show_path) { member_photo_path site.id, node, item }
  let(:edit_path) { edit_member_photo_path site.id, node, item }
  let(:delete_path) { delete_member_photo_path site.id, node, item }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        attach_file "item[in_image]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        select I18n.t("member.options.license_name.free"), from: 'item[license_name]'
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
  end
end
