require 'spec_helper'

describe Gws::Tabular::File::CsvImportJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
  let!(:column1) do
    create(:gws_tabular_column_file_upload_field, cur_site: site, cur_form: form, required: 'required')
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

    expect(Gws::Job::Log.count).to eq 1
    Gws::Job::Log.all.each do |log|
      expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
      expect(log.logs).not_to include(include('WARN'))
      expect(log.logs).not_to include(include('ERROR'))
    end

    form.reload
    release = form.current_release
    expect(release).to be_present
  end

  context "with gws/tabular/column/file_upload_field" do
    let(:file_model) { Gws::Tabular::File[form.current_release] }
    let(:root_dir) { unique_id }
    let(:csv_filepath) do
      I18n.with_locale(I18n.default_locale) do
        tmpfile(extname: ".csv") do |file|
          headers = [ file_model.t(:id), column1.name ]
          file.write SS::Csv::UTF8_BOM
          file.write headers.to_csv

          data_row = [ nil, "#{root_dir}/new1/logo.png" ]
          file.write data_row.to_csv
        end
      end
    end
    let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

    it do
      job = described_class.bind(site_id: site, user_id: user)
      job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_csv_file.id)

      expect(Gws::Job::Log.count).to eq 2
      Gws::Job::Log.all.reorder(created: -1).first.tap do |log|
        # puts log.logs.join
        expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(/INFO -- : .* CSVファイルのインポートの場合、#{column1.name}はインポートできません。/)

        # expect(log.logs).not_to include(include('WARN'))
        expect(log.logs).to include(/WARN -- : .* インポートできませんでした。/)
        expect(log.logs).not_to include(include('ERROR'))
      end

      expect(file_model.all.count).to eq 0
    end
  end
end
