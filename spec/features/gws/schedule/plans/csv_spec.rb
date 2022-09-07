require 'spec_helper'

describe "gws_schedule_csv", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:facility) { create :gws_facility_item }
  let!(:plan0) { create :gws_schedule_plan, start_at: now.since(2.days).change(hour: 9) }
  let!(:plan1) do
    create(:gws_schedule_facility_plan, start_at: now.since(3.days).change(hour: 9),
      facility_ids: [ facility.id ], main_facility_id: facility.id
    )
  end
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
  let(:expected_basic_headers) do
    %i[id name start_at end_at allday category_id priority color].map do |key|
      Gws::Schedule::Plan.t(key)
    end
  end

  before do
    facility.columns = [ column0, column1 ]
    facility.save!

    plan1.facility_column_values = [
      column0.serialize_value(unique_id * 6),
      column1.serialize_value(rand(1..10))
    ]
    plan1.save!
  end

  context "csv download" do
    before { login_gws_user }

    it do
      visit gws_schedule_plans_path(site: site)
      within ".gws-schedule-box" do
        click_on I18n.t("ss.buttons.csv")
      end

      wait_for_download

      I18n.with_locale(I18n.default_locale) do
        csv = ::CSV.open(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
        csv_table = csv.read
        expect(csv_table.headers.length).to be > 10
        expect(csv_table.headers).to include(*expected_basic_headers)
        expect(csv_table.headers).to include("#{facility.name}/#{column0.name}")
        expect(csv_table.headers).to include("#{facility.name}/#{column1.name}")
        expect(csv_table.length).to eq 2

        # start_at order
        expect(csv_table[0][Gws::Schedule::Plan.t(:name)]).to eq plan0.name

        expect(csv_table[1][Gws::Schedule::Plan.t(:name)]).to eq plan1.name
        expect(csv_table[1]["#{facility.name}/#{column0.name}"]).to eq plan1.facility_column_values[0].value
        expect(csv_table[1]["#{facility.name}/#{column1.name}"]).to eq plan1.facility_column_values[1].value
      end
    end
  end
end
