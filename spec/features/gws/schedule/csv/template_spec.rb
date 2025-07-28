require 'spec_helper'

describe "gws_schedule_csv", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:facility) { create :gws_facility_item }
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

    login_gws_user
  end

  context "when csv templae is downloaded" do
    it do
      visit gws_schedule_csv_path(site: site)
      click_on I18n.t('ss.links.download_template')

      wait_for_download

      I18n.with_locale(I18n.default_locale) do
        csv = ::CSV.open(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
        csv_table = csv.read
        expect(csv_table.headers.length).to be > 10
        expect(csv_table.headers).to include(*expected_basic_headers)
        expect(csv_table.headers).to include("#{facility.name}/#{column0.name}")
        expect(csv_table.headers).to include("#{facility.name}/#{column1.name}")
        expect(csv_table.length).to eq 0
      end
    end
  end
end
