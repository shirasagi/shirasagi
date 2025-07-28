require 'spec_helper'

describe Gws::Tabular::File::ZipImportJob, dbscope: :example do
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

    context "when csv is 'new1/logo.png' and zip entry is 'new1/logo.png'" do
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
      let(:zip_filepath) do
        path = tmpfile(extname: ".zip")
        SS::Zip::Writer.create(path) do |zip_writer|
          zip_writer.add_file("#{root_dir}/files.csv") do |io|
            IO.copy_stream(csv_filepath, io)
          end
          zip_writer.add_file("#{root_dir}/new1/logo.png") do |io|
            IO.copy_stream("#{Rails.root}/spec/fixtures/ss/logo.png", io)
          end
        end
        path
      end
      let(:ss_zip_file) { tmp_ss_file(user: user, contents: zip_filepath) }

      it do
        job = described_class.bind(site_id: site, user_id: user)
        job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_zip_file.id)

        expect(Gws::Job::Log.count).to eq 2
        Gws::Job::Log.all.reorder(created: -1).first.tap do |log|
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
          file_data.read_tabular_value(column1).tap do |file|
            expect(file).to be_present
            expect(file.name).to eq "logo.png"
            expect(file.filename).to eq "logo.png"
            expect(file.content_type).to be_present
            expect(file.size).to be > 0
            expect(::File.size(file.path)).to be > 0
            expect(file.owner_item_id.to_s).to eq file_data.id.to_s
            expect(file.owner_item_type).to eq file_data.class.name
          end
        end
      end
    end

    # ファイル名の先頭の数字は重複の可能性を考えてユニークになるように付加したものなのでインポート時には取り除かれるはず。
    context "when csv is 'new1/10_logo.png' and zip entry is 'new1/10_logo.png'" do
      let(:csv_filepath) do
        I18n.with_locale(I18n.default_locale) do
          tmpfile(extname: ".csv") do |file|
            headers = [ file_model.t(:id), column1.name ]
            file.write SS::Csv::UTF8_BOM
            file.write headers.to_csv

            data_row = [ nil, "#{root_dir}/new1/10_logo.png" ]
            file.write data_row.to_csv
          end
        end
      end
      let(:zip_filepath) do
        path = tmpfile(extname: ".zip")
        SS::Zip::Writer.create(path) do |zip_writer|
          zip_writer.add_file("#{root_dir}/files.csv") do |io|
            IO.copy_stream(csv_filepath, io)
          end
          zip_writer.add_file("#{root_dir}/new1/10_logo.png") do |io|
            IO.copy_stream("#{Rails.root}/spec/fixtures/ss/logo.png", io)
          end
        end
        path
      end
      let(:ss_zip_file) { tmp_ss_file(user: user, contents: zip_filepath) }

      it do
        job = described_class.bind(site_id: site, user_id: user)
        job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_zip_file.id)

        expect(Gws::Job::Log.count).to eq 2
        Gws::Job::Log.all.reorder(created: -1).first.tap do |log|
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
          file_data.read_tabular_value(column1).tap do |file|
            expect(file).to be_present
            expect(file.name).to eq "logo.png"
            expect(file.filename).to eq "logo.png"
            expect(file.content_type).to be_present
            expect(file.size).to be > 0
            expect(::File.size(file.path)).to be > 0
            expect(file.owner_item_id.to_s).to eq file_data.id.to_s
            expect(file.owner_item_type).to eq file_data.class.name
          end
        end
      end
    end

    context "when csv is 'logo.png' and zip entry is 'logo.png'" do
      let(:csv_filepath) do
        I18n.with_locale(I18n.default_locale) do
          tmpfile(extname: ".csv") do |file|
            headers = [ file_model.t(:id), column1.name ]
            file.write SS::Csv::UTF8_BOM
            file.write headers.to_csv

            data_row = [ nil, "#{root_dir}/logo.png" ]
            file.write data_row.to_csv
          end
        end
      end
      let(:zip_filepath) do
        path = tmpfile(extname: ".zip")
        SS::Zip::Writer.create(path) do |zip_writer|
          zip_writer.add_file("#{root_dir}/files.csv") do |io|
            IO.copy_stream(csv_filepath, io)
          end
          zip_writer.add_file("#{root_dir}/logo.png") do |io|
            IO.copy_stream("#{Rails.root}/spec/fixtures/ss/logo.png", io)
          end
        end
        path
      end
      let(:ss_zip_file) { tmp_ss_file(user: user, contents: zip_filepath) }

      it do
        job = described_class.bind(site_id: site, user_id: user)
        job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_zip_file.id)

        expect(Gws::Job::Log.count).to eq 2
        Gws::Job::Log.all.reorder(created: -1).first.tap do |log|
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
          file_data.read_tabular_value(column1).tap do |file|
            expect(file).to be_present
            expect(file.name).to eq "logo.png"
            expect(file.filename).to eq "logo.png"
            expect(file.content_type).to be_present
            expect(file.size).to be > 0
            expect(::File.size(file.path)).to be > 0
            expect(file.owner_item_id.to_s).to eq file_data.id.to_s
            expect(file.owner_item_type).to eq file_data.class.name
          end
        end
      end
    end

    context "when attachments are not found" do
      let(:csv_filepath) do
        I18n.with_locale(I18n.default_locale) do
          tmpfile(extname: ".csv") do |file|
            headers = [ file_model.t(:id), column1.name ]
            file.write SS::Csv::UTF8_BOM
            file.write headers.to_csv

            data_row = [ nil, "#{root_dir}/logo.png" ]
            file.write data_row.to_csv
          end
        end
      end
      let(:zip_filepath) do
        path = tmpfile(extname: ".zip")
        SS::Zip::Writer.create(path) do |zip_writer|
          zip_writer.add_file("#{root_dir}/files.csv") do |io|
            IO.copy_stream(csv_filepath, io)
          end
        end
        path
      end
      let(:ss_zip_file) { tmp_ss_file(user: user, contents: zip_filepath) }

      it do
        job = described_class.bind(site_id: site, user_id: user)
        job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_zip_file.id)

        expect(Gws::Job::Log.count).to eq 2
        Gws::Job::Log.all.reorder(created: -1).first.tap do |log|
          expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)

          message = "#{column1.name} に指定されているファイル #{root_dir}/logo.png がZIP内に見つかりませんでした。"
          expect(log.logs).to include(/WARN -- : .* #{::Regexp.escape(message)}/)
          expect(log.logs).to include(/WARN -- : .* インポートできませんでした。/)

          expect(log.logs).not_to include(include('ERROR'))
        end

        expect(file_model.all.count).to eq 0
      end
    end
  end
end
