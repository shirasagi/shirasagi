require 'spec_helper'

describe "postal_codes", type: :feature, dbscope: :example do
  let(:item) { create :sys_postal_code }
  let(:index_path) { sys_postal_codes_path }
  let(:new_path) { new_sys_postal_code_path }
  let(:show_path) { sys_postal_codes_path item }
  let(:edit_path) { edit_sys_postal_code_path item }
  let(:delete_path) { delete_sys_postal_code_path item }
  let(:download_path) { download_sys_postal_codes_path }
  let(:import_path) { import_sys_postal_codes_path }

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
    before { login_sys_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[code]", with: "code"
        fill_in "item[prefecture]", with: "prefecture"
        fill_in "item[prefecture_kana]", with: "prefecture_kana"
        fill_in "item[prefecture_code]", with: "prefecture_code"
        fill_in "item[city]", with: "city"
        fill_in "item[city_kana]", with: "city_kana"
        fill_in "item[town]", with: "city"
        fill_in "item[town_kana]", with: "town_kana"
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
        fill_in "item[code]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end

    it "#download" do
      visit download_path
      expect(current_path).to eq download_path
    end

    it "#import" do
      visit import_path
      expect(current_path).to eq import_path

      click_button I18n.t('ss.buttons.import')
      expect(current_path).to eq import_path
      expect(page).to have_css("#errorExplanation")

      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/sys/postal_code.csv"
        click_button I18n.t('ss.buttons.import')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_import'))
    end
  end

  context "with keyword" do
    before { login_sys_user }

    it do
      # ensure that item is created
      item

      visit index_path
      within "form.index-search" do
        fill_in "s[keyword]", with: item.code
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".title", text: item.code)

      visit index_path
      within "form.index-search" do
        fill_in "s[keyword]", with: unique_id
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_no_css(".title", text: item.code)
    end
  end
end
