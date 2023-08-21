require 'spec_helper'

describe "member_photo_spots", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :member_node_photo_spot, filename: "photo-spots", name: "photo-spots" }
  let(:item) { create(:member_photo_spot, cur_node: node) }
  let(:index_path) { member_photo_spots_path site.id, node }
  let(:new_path) { new_member_photo_spot_path site.id, node }
  let(:show_path) { member_photo_spot_path site.id, node, item }
  let(:edit_path) { edit_member_photo_spot_path site.id, node, item }
  let(:delete_path) { delete_member_photo_spot_path site.id, node, item }

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
        fill_in "item[basename]", with: "sample"
        click_button I18n.t('ss.buttons.save')
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
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end
  end
end
