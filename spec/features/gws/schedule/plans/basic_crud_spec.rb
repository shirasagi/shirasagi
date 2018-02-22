require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let(:site) { gws_site }
    let(:item) { create :gws_schedule_plan }
    let(:index_path) { gws_schedule_plans_path site }
    let(:new_path) { new_gws_schedule_plan_path site }
    let(:show_path) { gws_schedule_plan_path site, item }
    let(:edit_path) { edit_gws_schedule_plan_path site, item }
    let(:delete_path) { soft_delete_gws_schedule_plan_path site, item }

    before { login_gws_user }

    it "#index" do
      item
      visit index_path
      wait_for_ajax
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_content(item.name)
    end

    it "#events" do
      item
      today = Time.zone.today
      sdate = today - today.day + 1.day
      edate = sdate + 1.month
      visit "#{index_path}/events.json?s[start]=#{sdate}&s[end]=#{edate}"
      expect(page.body).to have_content(item.name)
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        click_button "保存"
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#show" do
      visit show_path
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#delete" do
      item
      visit delete_path
      within "form" do
        click_button "削除"
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end
  end
end
