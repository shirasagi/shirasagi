require 'spec_helper'

describe "gws_schedule_csv", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  before { login_gws_user }

  context "when existing plans are updated" do
    let!(:now) { Time.zone.now.beginning_of_hour + 1.hour }
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

    context "with minimal required fields" do
      let(:name0) { unique_id }
      let(:name1) { unique_id }
      let!(:plan_to_csv) do
        plan_to_csv = Gws::Schedule::Plan.create!(
          cur_site: site, cur_user: user,
          name: name0, start_at: now, end_at: now + 1.hour, member_ids: [user.id]
        )
        plan_to_csv.name = name1
        plan_to_csv
      end

      it do
        expect(page).to have_css("div.mb-1", text: I18n.t('gws/schedule.import.count', count: 1))
        expect(Gws::Schedule::Plan.all.count).to eq 1
        Gws::Schedule::Plan.all.first.tap do |plan|
          expect(plan.site_id).to eq plan_to_csv.site_id
          expect(plan.name).to eq name1
          expect(plan.start_at).to eq plan_to_csv.start_at
          expect(plan.end_at).to eq plan_to_csv.end_at
          expect(plan.member_ids).to include(user.id)
        end
      end
    end
  end
end
