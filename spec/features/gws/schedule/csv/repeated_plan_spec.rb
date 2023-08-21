require 'spec_helper'

describe "gws_schedule_csv", type: :feature, dbscope: :example, js: true do
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

  context "when repeated plans are updated" do
    let!(:now) { Time.zone.now.beginning_of_hour + 1.hour }
    let!(:this_week_monday) { now.wday <= 1 ? now + (1 - now.wday).days : now - (now.wday - 1).days }
    let!(:next_week_monday) { this_week_monday + 7.days }
    let(:name) { unique_id }
    let(:start_at) { next_week_monday }
    let(:end_at) { start_at + 1.hour }
    let(:repeat_start) { start_at.to_date }
    let(:repeat_end) { (start_at + 4.days).to_date }
    let!(:repeated_plan) do
      Gws::Schedule::Plan.create!(
        cur_site: site, cur_user: user,
        name: name, start_at: start_at, end_at: end_at, member_ids: [user.id],
        repeat_type: "daily", interval: 1, repeat_base: "date", wdays: [], repeat_start: repeat_start, repeat_end: repeat_end
      )
    end
    let!(:csv_file) do
      tmpfile(extname: ".csv", binary: true) do |f|
        enum = Gws::Schedule::PlanCsv::Exporter.enum_csv([ plan_to_csv ], site: site, user: user, model: Gws::Schedule::Plan)
        enum.each do |csv|
          f.write csv
        end
      end
    end

    before do
      visit gws_schedule_csv_path(site: site)
      within "form#import_form" do
        attach_file "item[in_file]", csv_file
        page.accept_confirm do
          click_on I18n.t("ss.import")
        end
      end
    end

    context "with master repeated plan (first repeated plan)" do
      let(:name1) { unique_id }
      let(:start_at1) { start_at + 1.hour }
      let(:end_at1) { start_at1 + 1.hour }
      let!(:plan_to_csv) do
        plan = Gws::Schedule::Plan.where(repeat_plan_id: repeated_plan.repeat_plan_id).first
        plan.name = name1
        plan.start_at = start_at1
        plan.end_at = end_at1
        plan
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
        expect(Gws::Schedule::Plan.all.count).to eq 5
        # only first plan is updated
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq name1
          expect(plan.start_at).to eq start_at1
          expect(plan.end_at).to eq end_at1
          expect(plan.member_ids).to include(user.id)
          expect(plan.repeat_plan).to be_present
        end
        # second plan is remained same
        Gws::Schedule::Plan.all.second.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq name
          expect(plan.start_at).to eq start_at + 1.day
          expect(plan.end_at).to eq end_at + 1.day
          expect(plan.member_ids).to include(user.id)
          expect(plan.repeat_plan).to be_present
        end
        # last plan is also remained same
        Gws::Schedule::Plan.all.last.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq name
          expect(plan.start_at).to eq start_at + 4.days
          expect(plan.end_at).to eq end_at + 4.days
          expect(plan.member_ids).to include(user.id)
          expect(plan.repeat_plan).to be_present
        end
      end
    end

    context "with descendant repeated plan (second repeated plan)" do
      let(:name1) { unique_id }
      let(:start_at1) { start_at + 1.day + 1.hour }
      let(:end_at1) { start_at1 + 2.hours }
      let!(:plan_to_csv) do
        plan = Gws::Schedule::Plan.where(repeat_plan_id: repeated_plan.repeat_plan_id).second
        plan.name = name1
        plan.start_at = start_at1
        plan.end_at = end_at1
        plan
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
        expect(Gws::Schedule::Plan.all.count).to eq 5
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq name
          expect(plan.start_at).to eq start_at
          expect(plan.end_at).to eq end_at
          expect(plan.member_ids).to include(user.id)
          expect(plan.repeat_plan).to be_present
        end
        Gws::Schedule::Plan.all.second.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq name1
          expect(plan.start_at).to eq start_at1
          expect(plan.end_at).to eq end_at1
          expect(plan.member_ids).to include(user.id)
          expect(plan.repeat_plan).to be_present
        end
        Gws::Schedule::Plan.all.last.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq name
          expect(plan.start_at).to eq start_at + 4.days
          expect(plan.end_at).to eq end_at + 4.days
          expect(plan.member_ids).to include(user.id)
          expect(plan.repeat_plan).to be_present
        end
      end
    end
  end
end
