require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:group_ids) { [user.group_ids] }
  let(:member_ids) { [user.id] }
  let(:public_facility) { create :gws_facility_item, readable_setting_range: 'public' }
  let(:select_facility) { create :gws_facility_item, readable_setting_range: 'select', readable_group_ids: [group_ids], readable_member_ids: [member_ids] }
  let(:private_facility) { create :gws_facility_item, readable_setting_range: 'private' }

  let!(:public_item) { create :gws_schedule_facility_plan, facility_ids: [public_facility.id] }
  let!(:select_item) { create :gws_schedule_facility_plan, facility_ids: [select_facility.id] }
  let!(:private_item) { create :gws_schedule_facility_plan, facility_ids: [private_facility.id] }

  let(:public_new_path) { new_gws_schedule_facility_plan_path site, public_facility }
  let(:select_new_path) { new_gws_schedule_facility_plan_path site, select_facility }
  let(:private_new_path) { new_gws_schedule_facility_plan_path site, private_facility }

  context "閲覧権限" do
    before { login_gws_user }

    it "public" do
      visit public_new_path
      within "form#item-form" do
        fill_in "item[name]", with: public_item.name
        fill_in_datetime "item[start_at]", with: "2016/04/01 12:00"
        fill_in_datetime "item[end_at]", with: "2016/04/01 13:00"
        wait_cbox_open { click_button I18n.t('gws/schedule.facility_reservation.index') }
      end
      wait_for_cbox do
        click_on I18n.t('ss.buttons.close')
      end
      within 'form#item-form' do
        click_button I18n.t('ss.buttons.save')
      end

      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      Gws::Schedule::Plan.all.find(public_item.id) do |plan|
        expect(plan.name).to eq public_item.name
        expect(plan.readable_setting_range).to eq 'public'
      end
    end

    it "select" do
      visit select_new_path
      within "form#item-form" do
        fill_in "item[name]", with: select_item.name
        fill_in_datetime "item[start_at]", with: "2016/04/01 12:00"
        fill_in_datetime "item[end_at]", with: "2016/04/01 13:00"
        wait_cbox_open { click_button I18n.t('gws/schedule.facility_reservation.index') }
      end
      wait_for_cbox do
        click_on I18n.t('ss.buttons.close')
      end
      within 'form#item-form' do
        click_button I18n.t('ss.buttons.save')
      end

      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      Gws::Schedule::Plan.all.find(select_item.id) do |plan|
        expect(plan.name).to eq select_item.name
        expect(plan.readable_setting_range).to eq 'select'
        expect(plan.readable_member_ids).to eq select_item.readable_member_ids
        expect(plan.readable_group_ids).to eq select_item.readable_group_ids
      end
    end

    it "private" do
      visit private_new_path
      within "form#item-form" do
        fill_in "item[name]", with: private_item.name
        fill_in_datetime "item[start_at]", with: "2016/04/01 12:00"
        fill_in_datetime "item[end_at]", with: "2016/04/01 13:00"
        wait_cbox_open { click_button I18n.t('gws/schedule.facility_reservation.index') }
      end
      wait_for_cbox do
        click_on I18n.t('ss.buttons.close')
      end
      within 'form#item-form' do
        click_button I18n.t('ss.buttons.save')
      end

      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      Gws::Schedule::Plan.all.find(private_item.id) do |plan|
        expect(plan.name).to eq private_item.name
        expect(plan.readable_setting_range).to eq 'private'
      end
    end
  end
end
