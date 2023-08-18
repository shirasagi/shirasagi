require 'spec_helper'

describe "gws_schedule_csv", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:facility) { create :gws_facility_item }
  let!(:now) { Time.zone.now.change(hour: 9) }
  let!(:csv_file) do
    tmpfile(extname: ".csv", binary: true) do |f|
      f.write ''
    end
  end

  before { login_gws_user }

  context "when plans are imported as new plans" do
    let!(:plan_to_csv) do
      Gws::Schedule::Plan.create!(
        cur_site: site, cur_user: user,
        name: unique_id, start_at: now, end_at: now + 1.hour, member_ids: [user.id],
        facility_ids: [ facility.id ], main_facility_id: facility.id
      )
    end

    context "with basic facility" do
      before do
        ::File.open(csv_file, "wb") do |f|
          enum = Gws::Schedule::PlanCsv::Exporter.enum_csv([ plan_to_csv ], site: site, user: user, model: Gws::Schedule::Plan)
          enum.each do |csv|
            f.write csv
          end
        end

        Gws::Schedule::Plan.all.destroy_all

        visit gws_schedule_csv_path(site: site)
        within "form#import_form" do
          attach_file "item[in_file]", csv_file
          page.accept_confirm do
            click_on I18n.t("ss.import")
          end
        end
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq plan_to_csv.name
          expect(plan.start_at).to eq plan_to_csv.start_at
          expect(plan.end_at).to eq plan_to_csv.end_at
          expect(plan.member_ids).to include(user.id)
          expect(plan.facility_ids).to include(facility.id)
          expect(plan.main_facility_id).to eq facility.id
          expect(plan.facility_column_values).to be_blank
        end
      end
    end

    context "with facility having columns" do
      let(:column0) do
        Gws::Column::TextField.create(
          site: site, form: facility, name: unique_id, order: 10, required: 'optional', input_type: 'text'
        )
      end
      let(:column1) do
        Gws::Column::NumberField.create(
          site: site, form: facility, name: unique_id, order: 20, required: 'optional', minus_type: 'normal'
        )
      end
      let(:column0_value) { unique_id * 6 }
      let(:column1_value) { rand(1..10) }

      before do
        facility.columns = [ column0, column1 ]
        facility.save!

        plan_to_csv.facility_column_values = [
          column0.serialize_value(column0_value),
          column1.serialize_value(column1_value)
        ]
        plan_to_csv.save!

        ::File.open(csv_file, "wb") do |f|
          enum = Gws::Schedule::PlanCsv::Exporter.enum_csv([ plan_to_csv ], site: site, user: user, model: Gws::Schedule::Plan)
          enum.each do |csv|
            f.write csv
          end
        end

        Gws::Schedule::Plan.all.destroy_all

        visit gws_schedule_csv_path(site: site)
        within "form#import_form" do
          attach_file "item[in_file]", csv_file
          page.accept_confirm do
            click_on I18n.t("ss.import")
          end
        end
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq plan_to_csv.name
          expect(plan.start_at).to eq plan_to_csv.start_at
          expect(plan.end_at).to eq plan_to_csv.end_at
          expect(plan.member_ids).to include(user.id)
          expect(plan.facility_ids).to include(facility.id)
          expect(plan.main_facility_id).to eq facility.id
          expect(plan.facility_column_values).to have(2).items
          plan.facility_column_values.find_by(name: column0.name).tap do |column_value|
            expect(column_value.value).to eq column0_value
          end
          plan.facility_column_values.find_by(name: column1.name).tap do |column_value|
            expect(column_value.value).to eq column1_value.to_f.to_s
          end
        end
      end
    end
  end

  context "when plans are updated" do
    let!(:plan_with_facility) do
      Gws::Schedule::Plan.create!(
        cur_site: site, cur_user: user,
        name: unique_id, start_at: now, end_at: now + 1.hour, member_ids: [user.id],
        facility_ids: [ facility.id ], main_facility_id: facility.id
      )
    end
    let!(:facility1) { create :gws_facility_item }
    let!(:plan_to_csv) do
      plan_with_facility.facility_ids = [ facility1.id ]
      plan_with_facility.main_facility_id = facility1.id
      plan_with_facility
    end

    context "with basic facility" do
      before do
        ::File.open(csv_file, "wb") do |f|
          enum = Gws::Schedule::PlanCsv::Exporter.enum_csv([ plan_to_csv ], site: site, user: user, model: Gws::Schedule::Plan)
          enum.each do |csv|
            f.write csv
          end
        end

        visit gws_schedule_csv_path(site: site)
        within "form#import_form" do
          attach_file "item[in_file]", csv_file
          page.accept_confirm do
            click_on I18n.t("ss.import")
          end
        end
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq plan_to_csv.name
          expect(plan.start_at).to eq plan_to_csv.start_at
          expect(plan.end_at).to eq plan_to_csv.end_at
          expect(plan.member_ids).to include(user.id)
          expect(plan.facility_ids).to include(facility1.id)
          expect(plan.main_facility_id).to eq facility1.id
          expect(plan.facility_column_values).to be_blank
        end
      end
    end
  end
end
