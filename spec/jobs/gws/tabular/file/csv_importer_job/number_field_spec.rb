require 'spec_helper'

describe Gws::Tabular::File::CsvImportJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
  let!(:column1) do
    create(
      :gws_tabular_column_number_field, cur_site: site, cur_form: form, required: 'optional',
      field_type: field_type, min_value: nil, max_value: nil, default_value: nil)
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

    form.reload
    release = form.current_release
    expect(release).to be_present
  end

  context "with gws/tabular/column/enum_field" do
    let(:file_model) { Gws::Tabular::File[form.current_release] }

    context "field_type is 'integer'" do
      let(:field_type) { "integer" }

      context "with actual value" do
        let(:int_value) { 17 }

        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ file_model.t(:id), column1.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ BSON::ObjectId.new.to_s, int_value ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 2
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(file_model.all.count).to eq 1
          file_model.all.first.tap do |file_data|
            expect(file_data.site_id).to eq site.id
            expect(file_data.space_id.to_s).to eq space.id.to_s
            expect(file_data.form_id.to_s).to eq form.id.to_s
            expect(file_data.read_tabular_value(column1)).to eq int_value
          end
        end
      end

      context "with invalid value" do
        let(:int_value) { unique_id }

        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ file_model.t(:id), column1.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ BSON::ObjectId.new.to_s, int_value ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 2
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(file_model.all.count).to eq 1
          file_model.all.first.tap do |file_data|
            expect(file_data.site_id).to eq site.id
            expect(file_data.space_id.to_s).to eq space.id.to_s
            expect(file_data.form_id.to_s).to eq form.id.to_s
            expect(file_data.read_tabular_value(column1)).to be_blank
          end
        end
      end
    end

    context "field_type is 'float'" do
      let(:field_type) { "float" }

      context "with actual value" do
        let(:float_value) { 3.14 }

        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ file_model.t(:id), column1.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ BSON::ObjectId.new.to_s, float_value ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 2
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(file_model.all.count).to eq 1
          file_model.all.first.tap do |file_data|
            expect(file_data.site_id).to eq site.id
            expect(file_data.space_id.to_s).to eq space.id.to_s
            expect(file_data.form_id.to_s).to eq form.id.to_s
            expect(file_data.read_tabular_value(column1)).to eq float_value
          end
        end
      end

      context "with invalid value" do
        let(:float_value) { unique_id }

        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ file_model.t(:id), column1.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ BSON::ObjectId.new.to_s, float_value ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 2
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(file_model.all.count).to eq 1
          file_model.all.first.tap do |file_data|
            expect(file_data.site_id).to eq site.id
            expect(file_data.space_id.to_s).to eq space.id.to_s
            expect(file_data.form_id.to_s).to eq form.id.to_s
            expect(file_data.read_tabular_value(column1)).to be_blank
          end
        end
      end
    end

    context "field_type is 'decimal'" do
      let(:field_type) { "decimal" }

      context "with actual value" do
        let(:decimal_value) { BigDecimal("3.14") }

        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ file_model.t(:id), column1.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ BSON::ObjectId.new.to_s, decimal_value ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 2
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(file_model.all.count).to eq 1
          file_model.all.first.tap do |file_data|
            expect(file_data.site_id).to eq site.id
            expect(file_data.space_id.to_s).to eq space.id.to_s
            expect(file_data.form_id.to_s).to eq form.id.to_s
            expect(file_data.read_tabular_value(column1)).to eq decimal_value
          end
        end
      end

      context "with invalid value" do
        let(:decimal_value) { unique_id }

        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ file_model.t(:id), column1.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ BSON::ObjectId.new.to_s, decimal_value ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 2
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(file_model.all.count).to eq 1
          file_model.all.first.tap do |file_data|
            expect(file_data.site_id).to eq site.id
            expect(file_data.space_id.to_s).to eq space.id.to_s
            expect(file_data.form_id.to_s).to eq form.id.to_s
            expect(file_data.read_tabular_value(column1)).to be_blank
          end
        end
      end
    end
  end
end
