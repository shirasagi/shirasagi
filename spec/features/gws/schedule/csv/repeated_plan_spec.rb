require 'spec_helper'

describe "gws_schedule_csv", type: :feature, dbscope: :example, tmpdir: true, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  before { login_gws_user }

  context "when repeated plans are imported as new plans" do
    let!(:now) { Time.zone.now.beginning_of_hour + 1.hour }
    let!(:this_week_monday) { now.wday <= 1 ? now + (1 - now.wday).days : now - (now.wday - 1).days }
    let!(:next_week_monday) { this_week_monday + 7.days }
    let!(:csv_file) do
      tmpfile(extname: ".csv", binary: true) do |f|
        plan_to_csv
        enum = Gws::Schedule::PlanCsv::Exporter.enum_csv(Gws::Schedule::Plan.all, site: site, user: user)
        enum.each do |csv|
          f.write csv
        end
      end
    end

    before do
      Gws::Schedule::Plan.all.destroy_all

      visit gws_schedule_csv_path(site: site)
      within "form#import_form" do
        attach_file "item[in_file]", csv_file
        page.accept_confirm do
          click_on I18n.t("ss.import")
        end
      end
    end

    context "with daily repeated plan" do
      let(:start_at) { next_week_monday }
      let(:end_at) { start_at + 1.hour }
      let(:repeat_start) { start_at.to_date }
      let(:repeat_end) { (start_at + 4.days).to_date }
      let!(:plan_to_csv) do
        Gws::Schedule::Plan.create!(
          cur_site: site, cur_user: user,
          name: unique_id, start_at: start_at, end_at: end_at, member_ids: [user.id],
          repeat_type: "daily", interval: 1, repeat_base: "date", wdays: [], repeat_start: repeat_start, repeat_end: repeat_end
        )
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 5))
        expect(Gws::Schedule::Plan.all.count).to eq 5
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq plan_to_csv.name
          expect(plan.start_at).to eq plan_to_csv.start_at
          expect(plan.end_at).to eq plan_to_csv.end_at
          expect(plan.member_ids).to include(user.id)
          expect(plan.repeat_plan).to be_blank
        end
      end
    end
  end
end
