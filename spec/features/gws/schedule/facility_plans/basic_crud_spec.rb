require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:facility) { create :gws_facility_item }
  let(:group_ids) { [ user.group_ids ] }
  let(:member_ids) { [ user.id ] }
  let(:public_facility) { create :gws_facility_item, readable_setting_range: 'public' }
  let(:select_facility) { create :gws_facility_item, readable_setting_range: 'select', readable_group_ids: [ group_ids ], readable_member_ids: [ member_ids ] }
  let(:private_facility) { create :gws_facility_item, readable_setting_range: 'private' }

  context "with auth" do
    let!(:item) { create :gws_schedule_facility_plan, facility_ids: [ facility.id ] }
    let(:index_path) { gws_schedule_facility_plans_path site, facility }
    let(:new_path) { new_gws_schedule_facility_plan_path site, facility }
    let(:show_path) { gws_schedule_facility_plan_path site, facility, item }
    let(:edit_path) { edit_gws_schedule_facility_plan_path site, facility, item }
    let(:delete_path) { soft_delete_gws_schedule_facility_plan_path site, facility, item }

    let!(:public_item) { create :gws_schedule_facility_plan, facility_ids: [ public_facility.id ] }
    let!(:select_item) { create :gws_schedule_facility_plan, facility_ids: [ select_facility.id ] }
    let!(:private_item) { create :gws_schedule_facility_plan, facility_ids: [ private_facility.id ] }

    let(:public_new_path) { new_gws_schedule_facility_plan_path site, public_facility }
    let(:select_new_path) { new_gws_schedule_facility_plan_path site, select_facility }
    let(:private_new_path) { new_gws_schedule_facility_plan_path site, private_facility }

    before { login_gws_user }

    it "#index" do
      visit index_path
      wait_for_ajax
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_content(item.name)
    end

    it "#events" do
      sdate = item.start_at.to_date.beginning_of_month
      edate = item.end_at.to_date.beginning_of_month + 1.month
      visit "#{index_path}/events.json?s[start]=#{sdate}&s[end]=#{edate}"
      expect(page.body).to have_content(item.name)
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
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
      expect(current_path).to eq show_path
      within ".nav-menu" do
        click_link I18n.t('ss.links.delete')
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_ajax
      expect(current_path).to eq index_path
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end

    context 'with gws_schedule_facility_plan_few_days' do
      let!(:item) { create :gws_schedule_facility_plan_few_days, facility_ids: [facility.id] }

      it "#index" do
        visit index_path
        wait_for_ajax
        expect(current_path).not_to eq sns_login_path
        expect(page).to have_content(item.name)
      end

      it "#events" do
        sdate = item.start_on
        edate = item.end_on
        visit "#{index_path}/events.json?s[start]=#{sdate}&s[end]=#{edate}"
        expect(page.body).to have_content(item.name)
      end

      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "name"
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
        expect(current_path).to eq show_path
        within ".nav-menu" do
          click_link I18n.t('ss.links.delete')
        end
        within "form#item-form" do
          click_button I18n.t('ss.buttons.delete')
        end
        wait_for_ajax
        expect(current_path).to eq index_path
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      end
    end

    context "閲覧権限" do
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
end
