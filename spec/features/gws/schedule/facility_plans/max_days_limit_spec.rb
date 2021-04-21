require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:facility) { create :gws_facility_item }

  context "with max_days_limit" do
    let(:now) { Time.zone.now.change(month: 8, hour: 9) }
    let(:plan_name) { unique_id }

    shared_examples "a facility plan reservation" do
      before do
        facility.max_days_limit = 30
        facility.readable_member_ids = facility_readable_member_ids
        facility.user_ids = facility_user_ids
        facility.save!

        site.schedule_max_years = 0
        site.schedule_max_month = 3
        site.save!
      end

      it do
        Timecop.freeze(now) do
          login_user user

          visit gws_schedule_facility_plans_path(site: site, facility: facility)
          click_on I18n.t("gws/schedule.links.add_plan")

          within "#item-form" do
            fill_in "item[name]", with: plan_name
            fill_in "item[start_at]", with: I18n.l(start_at, format: :picker)
            # !!!be cafeful!!!
            # it is required to input twice
            fill_in "item[end_at]", with: I18n.l(end_at, format: :picker)
            fill_in "item[end_at]", with: I18n.l(end_at, format: :picker)
            click_on I18n.t("ss.buttons.save")
          end
          expect(page).to have_css(css_class, text: message)
          # wait for ajax
          expect(page).to have_content(plan_name)
        end
      end
    end

    context "with normal user" do
      let(:role) { create :gws_role, :gws_role_schedule_plan_editor, :gws_role_facility_item_user }
      let!(:user) { create :gws_user, gws_role_ids: [ role.id ], group_ids: gws_user.group_ids }
      let(:facility_readable_member_ids) { [ user.id ] }
      let(:facility_user_ids) { [] }

      context "when end_at is at the facility limit" do
        let(:start_at) { end_at - 1.hour }
        let(:end_at) { now + facility.max_days_limit.days }
        let(:css_class) { '#notice' }
        let(:message) { I18n.t('ss.notice.saved') }

        it_behaves_like "a facility plan reservation"
      end

      context "when end_at is over the facility limit" do
        let(:start_at) { end_at - 1.hour }
        let(:end_at) { now + facility.max_days_limit.days + 1.minute }
        let(:css_class) { '#errorExplanation' }
        let(:message) { I18n.t("gws/schedule.errors.faciliy_day_lte", count: facility.max_days_limit) }

        it_behaves_like "a facility plan reservation"
      end
    end

    context "with facility admin" do
      let(:role) { create :gws_role, :gws_role_schedule_plan_editor, :gws_role_facility_item_admin }
      let!(:user) { create :gws_user, gws_role_ids: [ role.id ], group_ids: gws_user.group_ids }
      let(:facility_readable_member_ids) { [ user.id ] }
      let(:facility_user_ids) { [ user.id ] }

      context "when end_at is at the limit" do
        let(:start_at) { end_at - 1.hour }
        let(:end_at) { now + facility.max_days_limit.days }
        let(:css_class) { '#notice' }
        let(:message) { I18n.t('ss.notice.saved') }

        it_behaves_like "a facility plan reservation"
      end

      context "when end_at is over the facility limit" do
        let(:start_at) { end_at - 1.hour }
        let(:end_at) { now + facility.max_days_limit.days + 1.minute }
        let(:css_class) { '#notice' }
        let(:message) { I18n.t('ss.notice.saved') }

        it_behaves_like "a facility plan reservation"
      end

      context "when start_at is over the site limit" do
        let(:start_at) { site.schedule_max_at.in_time_zone + 1.day + 10.hours }
        let(:end_at) { start_at + 1.hour }
        let(:css_class) { '#errorExplanation' }
        let(:message) { I18n.t('gws/schedule.errors.less_than_max_date', date: I18n.l(site.schedule_max_at, format: :long)) }

        it_behaves_like "a facility plan reservation"
      end
    end
  end
end
