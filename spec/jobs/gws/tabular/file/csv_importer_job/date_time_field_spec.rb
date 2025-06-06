require 'spec_helper'

describe Gws::Tabular::File::CsvImportJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
  let!(:column1) do
    create(:gws_tabular_column_date_time_field, cur_site: site, cur_form: form, required: 'optional', input_type: input_type)
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

    form.reload
    release = form.current_release
    expect(release).to be_present
  end

  context "with gws/tabular/column/date_time_field" do
    let(:file_model) { Gws::Tabular::File[form.current_release] }

    context "input_type is 'date'" do
      let(:input_type) { "date" }

      context "with actual value" do
        let(:date_value) { Time.zone.now.to_date }

        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ file_model.t(:id), column1.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ BSON::ObjectId.new.to_s, I18n.l(date_value, format: :csv) ]
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
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
          end

          expect(file_model.all.count).to eq 1
          file_model.all.first.tap do |file_data|
            expect(file_data.site_id).to eq site.id
            expect(file_data.space_id.to_s).to eq space.id.to_s
            expect(file_data.form_id.to_s).to eq form.id.to_s
            expect(file_data.read_tabular_value(column1)).to eq date_value
          end
        end
      end

      context "with invalid date" do
        let(:date_value) { ('a'..'z').to_a.sample(10).join }

        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ file_model.t(:id), column1.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ nil, date_value ]
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

    context "input_type is 'datetime'" do
      let(:input_type) { "datetime" }

      context "with actual value" do
        let(:time_value) { Time.zone.now.change(sec: 0) }

        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ file_model.t(:id), column1.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ BSON::ObjectId.new.to_s, I18n.l(time_value, format: :csv) ]
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
            expect(file_data.read_tabular_value(column1)).to eq time_value
          end
        end
      end

      context "with invalid date" do
        let(:time_value) { ('a'..'z').to_a.sample(10).join }

        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ file_model.t(:id), column1.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ nil, time_value ]
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
