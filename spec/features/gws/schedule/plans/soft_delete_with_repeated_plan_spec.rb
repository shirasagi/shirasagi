require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  context "soft delete with repeated plans" do
    let(:name) { unique_id }
    let(:text) { unique_id }
    let(:start_at) { Time.zone.parse('2018/03/07 14:00') }
    let(:end_at) { Time.zone.parse('2018/03/07 15:00') }
    let(:repeat_start) { Date.parse('2018/03/01') }
    let(:repeat_end) { Date.parse('2018/03/31') }
    let(:repeat_type) { 'weekly' }
    let(:repeat_type_label) { I18n.t("gws/schedule.options.repeat_type.#{repeat_type}") }
    let(:interval) { 3 }

    around do |example|
      Timecop.travel(Time.zone.parse('2018/3/5 14:00')) do
        example.run
      end
    end

    before { login_gws_user }

    context 'with delete all' do
      it do
        visit new_gws_schedule_plan_path(site)

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in_datetime "item[start_at]", with: start_at
          fill_in_datetime "item[end_at]", with: end_at
          select repeat_type_label, from: "item[repeat_type]"
          # select interval.to_s, from: "item[interval]"
          check 'item_wdays_3'
          fill_in_date "item[repeat_start]", with: repeat_start
          fill_in_date "item[repeat_end]", with: repeat_end
          fill_in "item[text]", with: text

          click_on I18n.t('ss.buttons.save')
        end

        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(Gws::Schedule::Plan.site(site).without_deleted.member(gws_user).count).to eq 4
        expect(Gws::Schedule::Plan.site(site).only_deleted.member(gws_user).count).to eq 0

        # wait until events are rendered
        expect(page).to have_css('.fc-view a.fc-event', text: name)

        # do soft delete at first item
        item = Gws::Schedule::Plan.site(site).without_deleted.member(gws_user).order_by(start_at: 1).second
        visit soft_delete_gws_schedule_plan_path(site, item)

        within 'form#item-form' do
          click_on I18n.t('ss.buttons.delete')
        end
        within '.gws-schedule-repeat-submit' do
          click_on I18n.t('gws/schedule.buttons.delete_all')
        end

        expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
        expect(Gws::Schedule::Plan.site(site).without_deleted.member(gws_user).count).to eq 0
        expect(Gws::Schedule::Plan.site(site).only_deleted.member(gws_user).count).to eq 4
      end
    end

    context 'with delete later' do
      it do
        visit new_gws_schedule_plan_path(site)

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in_datetime "item[start_at]", with: start_at
          fill_in_datetime "item[end_at]", with: end_at
          select repeat_type_label, from: "item[repeat_type]"
          # select interval.to_s, from: "item[interval]"
          check 'item_wdays_3'
          fill_in_date "item[repeat_start]", with: repeat_start
          fill_in_date "item[repeat_end]", with: repeat_end
          fill_in "item[text]", with: text

          click_on I18n.t('ss.buttons.save')
        end

        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(Gws::Schedule::Plan.site(site).without_deleted.member(gws_user).count).to eq 4
        expect(Gws::Schedule::Plan.site(site).only_deleted.member(gws_user).count).to eq 0

        # do soft delete at first item
        item = Gws::Schedule::Plan.site(site).without_deleted.member(gws_user).order_by(start_at: 1).second
        visit soft_delete_gws_schedule_plan_path(site, item)

        within 'form#item-form' do
          click_on I18n.t('ss.buttons.delete')
        end
        within '.gws-schedule-repeat-submit' do
          click_on I18n.t('gws/schedule.buttons.delete_later')
        end

        expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
        expect(Gws::Schedule::Plan.site(site).without_deleted.member(gws_user).count).to eq 1
        expect(Gws::Schedule::Plan.site(site).only_deleted.member(gws_user).count).to eq 3
      end
    end

    context 'with delete one' do
      it do
        visit new_gws_schedule_plan_path(site)

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in_datetime "item[start_at]", with: start_at
          fill_in_datetime "item[end_at]", with: end_at
          select repeat_type_label, from: "item[repeat_type]"
          # select interval.to_s, from: "item[interval]"
          check 'item_wdays_3'
          fill_in_date "item[repeat_start]", with: repeat_start
          fill_in_date "item[repeat_end]", with: repeat_end
          fill_in "item[text]", with: text

          click_on I18n.t('ss.buttons.save')
        end

        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(Gws::Schedule::Plan.site(site).without_deleted.member(gws_user).count).to eq 4
        expect(Gws::Schedule::Plan.site(site).only_deleted.member(gws_user).count).to eq 0

        # do soft delete at first item
        item = Gws::Schedule::Plan.site(site).without_deleted.member(gws_user).order_by(start_at: 1).third
        visit soft_delete_gws_schedule_plan_path(site, item)

        within 'form#item-form' do
          click_on I18n.t('ss.buttons.delete')
        end
        within '.gws-schedule-repeat-submit' do
          click_on I18n.t('gws/schedule.buttons.delete_one')
        end

        expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
        expect(Gws::Schedule::Plan.site(site).without_deleted.member(gws_user).count).to eq 3
        expect(Gws::Schedule::Plan.site(site).only_deleted.member(gws_user).count).to eq 1
      end
    end
  end
end
