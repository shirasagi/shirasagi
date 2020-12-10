require 'spec_helper'

describe "member_photos", type: :feature, dbscope: :example do
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

  context "set center and zoom" do
    before { login_cms_user }
    before do
    visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        attach_file "item[in_image]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        select I18n.t("member.options.license_name.free"), from: 'item[license_name]'
        click_button I18n.t('ss.buttons.save')
      end
    end

    it "#center position" do
      visit edit_path
      expect(item.center_setting).to eq "auto"
      expect(item.set_center_position).to eq nil
      within "form" do
        find("input[name='item[center_setting]'][value='designated_location']").set(true)
        fill_in "item[set_center_position]", with: "34.067035,134.589971"
        click_on I18n.t("ss.buttons.save")
      end
      item.reload
      expect(item.center_setting).to eq "designated_location"
      expect(item.set_center_position).to eq "34.067035,134.589971"
    end

    it "#center position validation" do
      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "90,134.589971"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).not_to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "90.1,134.589971"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "-90,134.589971"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).not_to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "-90.1,134.589971"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "34.067035,180"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).not_to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "34.067035,180.1"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "34.067035,-180"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).not_to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "34.067035,-180.1"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "134.589971,34.067035"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "34.067035"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "34.067035,134.589971,34.067035"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "latitude,longitude"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "34.067abc035,134.589971"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")
    end

    it "#zoom level" do
      visit edit_path
      expect(item.zoom_setting).to eq "auto"
      expect(item.set_zoom_level).to eq nil
      within "form" do
        find("input[name='item[zoom_setting]'][value='designated_level']").set(true)
        fill_in "item[set_zoom_level]", with: 10
        click_on I18n.t("ss.buttons.save")
      end
      item.reload
      expect(item.zoom_setting).to eq "designated_level"
      expect(item.set_zoom_level).to eq 10
    end

    it "#zoom level border value" do
      visit edit_path
      within "form" do
        fill_in "item[set_zoom_level]", with: 0
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_zoom_level]", with: 1
        click_on I18n.t("ss.buttons.save")
      end
      item.reload
      expect(item.set_zoom_level).to eq 1

      visit edit_path
      within "form" do
        fill_in "item[set_zoom_level]", with: 21
        click_on I18n.t("ss.buttons.save")
      end
      item.reload
      expect(item.set_zoom_level).to eq 21

      visit edit_path
      within "form" do
        fill_in "item[set_zoom_level]", with: 22
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")
    end
  end
end
