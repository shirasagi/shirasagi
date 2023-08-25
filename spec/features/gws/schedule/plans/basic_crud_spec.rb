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

    it "#crud" do
      item

      # index
      visit index_path
      wait_for_ajax
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_content(item.name)

      # events
      today = Time.zone.today
      sdate = today - today.day + 1.day
      edate = sdate + 1.month
      visit "#{index_path}/events.json?s[start]=#{sdate}&s[end]=#{edate}"
      expect(page.body).to have_content(item.name)

      # new
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # show
      visit show_path
      expect(page).to have_content(item.name)

      # edit
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # delete
      visit delete_path
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end
  end
end
