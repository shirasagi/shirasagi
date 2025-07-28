require 'spec_helper'

describe "gws_affair_capitals", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:year) { create(:gws_affair_capital_year) }
  let(:item) { create(:gws_affair_capital, year: year) }
  let(:index_path) { gws_affair_capitals_path site.id, year }
  let(:new_path) { new_gws_affair_capital_path site.id, year }
  let(:show_path) { gws_affair_capital_path site.id, year, item }
  let(:edit_path) { edit_gws_affair_capital_path site.id, year, item }
  let(:delete_path) { delete_gws_affair_capital_path site.id, year, item }

  context "basic crud" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[article_code]", with: 1
        fill_in "item[section_code]", with: 2
        fill_in "item[subsection_code]", with: 3
        fill_in "item[item_code]", with: 4
        fill_in "item[subitem_code]", with: 5
        fill_in "item[project_code]", with: 6
        fill_in "item[detail_code]", with: 7

        fill_in "item[project_name]", with: "事業名称"
        fill_in "item[description_name]", with: "説明名称"
        fill_in "item[item_name]", with: "節名称"
        fill_in "item[subitem_name]", with: "細節名称"

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.year.name)

      visit index_path
      expect(page).to have_css(".list-items", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[article_code]", with: 11
        fill_in "item[section_code]", with: 22
        fill_in "item[subsection_code]", with: 33
        fill_in "item[item_code]", with: 44
        fill_in "item[subitem_code]", with: 55
        fill_in "item[project_code]", with: 66
        fill_in "item[detail_code]", with: 77
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
    end

    it "#delete" do
      visit delete_path
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')
    end
  end
end
