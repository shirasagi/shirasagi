require 'spec_helper'

describe Gws::Tabular::File::CsvExporter, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form,
      input_type: "single", validation_type: "none", i18n_state: "enabled")
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

    expect(Gws::Job::Log.count).to eq 1
    Gws::Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end

    form.reload
    release = form.current_release
    expect(release).to be_present
  end

  context "export" do
    let(:file_model) { Gws::Tabular::File[form.current_release] }
    let(:translations) { i18n_translations(prefix: "text") }
    let!(:file_data) do
      file_model.create!(
        cur_site: site, cur_user: user, cur_space: space, cur_form: form,
        "col_#{column1.id}_translations" => translations)
    end

    it do
      criteria = file_model.site(site).allow(:read, user, site: site)
      exporter = Gws::Tabular::File::CsvExporter.new(
        site: site, user: user, space: space, form: form, release: form.current_release, criteria: criteria)
      csv = exporter.enum_csv(encoding: "UTF-8").to_a.join
      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(StringIO.new(csv), headers: true) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          csv_table[0].tap do |csv_row|
            expect(csv_row[file_model.t(:id)]).to eq file_data.id.to_s
            expect(csv_row["#{column1.name} (#{I18n.t("ss.options.lang.ja")})"]).to eq translations[:ja]
            expect(csv_row["#{column1.name} (#{I18n.t("ss.options.lang.en")})"]).to eq translations[:en]
          end
        end
      end
    end
  end
end
