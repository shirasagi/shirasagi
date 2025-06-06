require 'spec_helper'

describe Gws::Tabular::File::CsvImportJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, required: 'optional',
      input_type: "single", max_length: nil, i18n_default_value_translations: nil,
      validation_type: "none", i18n_state: i18n_state)
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

    form.reload
    release = form.current_release
    expect(release).to be_present
  end

  context "with gws/tabular/column/text_field" do
    context "when i18n_state is 'disabled'" do
      let(:i18n_state) { 'disabled' }
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let(:text_value) { "text-#{unique_id}" }

      let(:csv_filepath) do
        I18n.with_locale(I18n.default_locale) do
          tmpfile(extname: ".csv") do |file|
            headers = [ file_model.t(:id), column1.name ]
            file.write SS::Csv::UTF8_BOM
            file.write headers.to_csv

            data_row = [ BSON::ObjectId.new.to_s, text_value ]
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
          expect(file_data.read_tabular_value(column1)).to eq text_value
        end
      end
    end

    context "when i18n_state is 'enabled'" do
      let(:i18n_state) { 'enabled' }
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let(:text_value_translations) { i18n_translations(prefix: "text") }

      context "all locales are presented" do
        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [
                file_model.t(:id),
                "#{column1.name} (#{I18n.t("ss.options.lang.ja")})",
                "#{column1.name} (#{I18n.t("ss.options.lang.en")})",
              ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ "", text_value_translations[:ja], text_value_translations[:en] ]
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
            expect(file_data.read_tabular_value(column1)).to eq text_value_translations
          end
        end
      end

      context "all only ja locale is presented" do
        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [
                file_model.t(:id),
                "#{column1.name} (#{I18n.t("ss.options.lang.ja")})"
              ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ "", text_value_translations[:ja] ]
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
            file_data.read_tabular_value(column1).tap do |translations|
              expect(translations[:ja]).to eq text_value_translations[:ja]
              expect(translations[:en]).to be_blank
            end
          end
        end
      end

      context "all only en locale is presented" do
        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [
                file_model.t(:id),
                "#{column1.name} (#{I18n.t("ss.options.lang.en")})"
              ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ "", text_value_translations[:en] ]
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
            file_data.read_tabular_value(column1).tap do |translations|
              expect(translations[:ja]).to be_blank
              expect(translations[:en]).to eq text_value_translations[:en]
            end
          end
        end
      end
    end
  end
end
