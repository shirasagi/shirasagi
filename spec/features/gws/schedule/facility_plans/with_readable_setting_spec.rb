require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  context "with readable_setting" do
    let(:now) { Time.zone.now.beginning_of_hour }
    let(:start_at) { now.change(hour: 12) + 1.week }
    let(:end_at) { start_at + 1.hour }
    let(:name) { unique_id }

    before { login_gws_user }

    context 'with "public"' do
      let(:facility) { create :gws_facility_item, readable_setting_range: 'public' }

      it do
        visit new_gws_schedule_facility_plan_path(site: site, facility: facility)
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in_datetime "item[start_at]", with: start_at
          fill_in_datetime "item[end_at]", with: end_at

          click_on I18n.t('ss.buttons.save')
        end

        wait_for_notice I18n.t('ss.notice.saved')
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.name).to eq name
          expect(plan.readable_setting_range).to eq 'public'
          expect(plan.readable_group_ids).to be_blank
          expect(plan.readable_member_ids).to be_blank
          expect(plan.readable_custom_group_ids).to be_blank
        end
      end
    end

    context 'with "select"' do
      let(:user) { gws_user }
      let(:group_ids) { [user.group_ids] }
      let(:member_ids) { [user.id] }
      let!(:facility) do
        create(
          :gws_facility_item, readable_setting_range: 'select',
          readable_group_ids: group_ids, readable_member_ids: member_ids)
      end

      it do
        visit new_gws_schedule_facility_plan_path(site: site, facility: facility)
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in_datetime "item[start_at]", with: start_at
          fill_in_datetime "item[end_at]", with: end_at

          click_on I18n.t('ss.buttons.save')
        end

        wait_for_notice I18n.t('ss.notice.saved')
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.name).to eq name
          expect(plan.readable_setting_range).to eq 'select'
          expect(plan.readable_group_ids).to eq facility.readable_group_ids
          expect(plan.readable_member_ids).to eq facility.readable_member_ids
          expect(plan.readable_custom_group_ids).to be_blank
        end
      end
    end

    context 'with "private"' do
      let!(:facility) { create :gws_facility_item, readable_setting_range: 'private' }

      it do
        visit new_gws_schedule_facility_plan_path(site: site, facility: facility)
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in_datetime "item[start_at]", with: start_at
          fill_in_datetime "item[end_at]", with: end_at

          click_on I18n.t('ss.buttons.save')
        end

        wait_for_notice I18n.t('ss.notice.saved')
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.name).to eq name
          expect(plan.readable_setting_range).to eq 'private'
          expect(plan.readable_group_ids).to be_blank
          expect(plan.readable_member_ids).to eq [ gws_user.id ]
          expect(plan.readable_custom_group_ids).to be_blank
        end
      end
    end
  end
end
