require 'spec_helper'

describe "gws_schedule_csv", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:facility) { create :gws_facility_item }
  let(:now) { Time.zone.now.change(month: 8, day: 3, hour: 11, min: 30, sec: 0) }
  let!(:csv_file) do
    tmpfile(extname: ".csv", binary: true) do |f|
      f.write ''
    end
  end
  let(:plan_name) { unique_id }

  around do |example|
    travel_to(now) { example.run }
  end

  shared_examples "a facility plan import" do
    let(:plan_to_csv) do
      Gws::Schedule::Plan.new(
        cur_site: site, cur_user: user,
        name: plan_name, start_at: start_at, end_at: end_at, member_ids: [gws_user.id],
        facility_ids: [ facility.id ], main_facility_id: facility.id
      )
    end

    before do
      facility.max_days_limit = 30
      facility.readable_member_ids = facility_readable_member_ids
      facility.user_ids = facility_user_ids
      facility.save!

      site.schedule_max_years = 0
      site.schedule_max_month = 3
      site.save!

      ::File.open(csv_file, "wb") do |f|
        enum = Gws::Schedule::PlanCsv::Exporter.enum_csv([ plan_to_csv ], site: site, user: user, model: Gws::Schedule::Plan)
        enum.each do |csv|
          f.write csv
        end
      end
    end

    it do
      Gws::Schedule::Plan.all.destroy_all

      login_user user

      visit gws_schedule_csv_path(site: site)
      within "form#import_form" do
        attach_file "item[in_file]", csv_file
        page.accept_confirm do
          click_on I18n.t("ss.import")
        end
      end

      expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: count))
      expect(page).to have_css(css_class, text: message)

      expect(Gws::Schedule::Plan.all.count).to eq count
      if count > 0
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq site.id
          expect(plan.name).to eq plan_name
          expect(plan.start_at).to eq start_at
          expect(plan.end_at).to eq end_at
          expect(plan.member_ids).to include(gws_user.id)
          expect(plan.facility_ids).to include(facility.id)
          expect(plan.main_facility_id).to eq facility.id
          expect(plan.facility_column_values).to be_blank
        end
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
      let(:count) { 1 }
      let(:css_class) { ".import-saved" }
      let(:message) { I18n.t('gws/schedule.import.saved') }

      it_behaves_like "a facility plan import"
    end

    context "when end_at is over the facility limit" do
      let(:start_at) { end_at - 1.hour }
      let(:end_at) { now + facility.max_days_limit.days + 1.minute }
      let(:count) { 0 }
      let(:css_class) { ".import-error" }
      let(:message) { I18n.t("gws/schedule.errors.faciliy_day_lte", count: facility.max_days_limit) }

      it_behaves_like "a facility plan import"
    end
  end

  context "with facility admin" do
    let(:role) { create :gws_role, :gws_role_schedule_plan_editor, :gws_role_facility_item_admin }
    let!(:user) { create :gws_user, gws_role_ids: [ role.id ], group_ids: gws_user.group_ids }
    let(:facility_readable_member_ids) { [ user.id ] }
    let(:facility_user_ids) { [ user.id ] }

    context "when end_at is at the facility limit" do
      let(:start_at) { end_at - 1.hour }
      let(:end_at) { now + facility.max_days_limit.days }
      let(:count) { 1 }
      let(:css_class) { ".import-saved" }
      let(:message) { I18n.t('gws/schedule.import.saved') }

      it_behaves_like "a facility plan import"
    end

    context "when end_at is over the facility limit" do
      let(:start_at) { end_at - 1.hour }
      let(:end_at) { now + facility.max_days_limit.days + 1.minute }
      let(:count) { 1 }
      let(:css_class) { ".import-saved" }
      let(:message) { I18n.t('gws/schedule.import.saved') }

      it_behaves_like "a facility plan import"
    end

    context "when start_at is over the site limit" do
      let(:start_at) { site.schedule_max_at.in_time_zone + 1.day + 10.hours }
      let(:end_at) { start_at + 1.hour }
      let(:count) { 0 }
      let(:css_class) { ".import-error" }
      let(:message) { I18n.t('gws/schedule.errors.less_than_max_date', date: I18n.l(site.schedule_max_at, format: :long)) }

      it_behaves_like "a facility plan import"
    end
  end
end
