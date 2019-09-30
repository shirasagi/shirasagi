require 'spec_helper'

describe "gws_affair_capital_years", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:item) { create(:gws_affair_capital_year) }
  let(:index_path) { gws_affair_capital_years_path site.id }
  let(:new_path) { new_gws_affair_capital_year_path site.id }
  let(:show_path) { gws_affair_capital_year_path site.id, item }
  let(:edit_path) { edit_gws_affair_capital_year_path site.id, item }
  let(:delete_path) { delete_gws_affair_capital_year_path site.id, item }

  before do
    login_gws_user
  end

  context "basic crud" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "令和2年"
        fill_in "item[code]", with: 2020
        fill_in "item[start_date]", with: I18n.l(Time.zone.parse("2020/4/1"), format: :picker)
        fill_in "item[close_date]", with: I18n.l(Time.zone.parse("2021/3/31"), format: :picker)
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "令和3年"
        fill_in "item[code]", with: 20201
        fill_in "item[start_date]", with: I18n.l(Time.zone.parse("2021/4/1"), format: :picker)
        fill_in "item[close_date]", with: I18n.l(Time.zone.parse("2022/3/31"), format: :picker)
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end
  end
end
