require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:facility) { create :gws_facility_item }

  context "with auth" do
    let!(:item) { create :gws_schedule_facility_plan, facility_ids: [facility.id] }
    let(:index_path) { gws_schedule_facility_plans_path site, facility }
    let(:new_path) { new_gws_schedule_facility_plan_path site, facility }
    let(:show_path) { gws_schedule_facility_plan_path site, facility, item }
    let(:edit_path) { edit_gws_schedule_facility_plan_path site, facility, item }
    let(:delete_path) { soft_delete_gws_schedule_facility_plan_path site, facility, item }

    before { login_gws_user }

    it "#index" do
      visit index_path
      wait_for_ajax
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_content(item.name)
    end

    it "#events" do
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
        fill_in "item[start_at]", with: "2016/04/01 12:00"
        fill_in "item[end_at]", with: "2016/04/01 13:00"
        click_button I18n.t('gws/schedule.facility_reservation.index')
      end
      wait_for_cbox do
        click_on I18n.t('ss.buttons.close')
      end
      within 'form#item-form' do
        click_button I18n.t('ss.buttons.save')
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
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#delete" do
      visit index_path
      first('span.fc-title', text: item.name).click
      click_link I18n.t('ss.links.delete')
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_ajax
      expect(current_path).to eq index_path
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end
  end
end
