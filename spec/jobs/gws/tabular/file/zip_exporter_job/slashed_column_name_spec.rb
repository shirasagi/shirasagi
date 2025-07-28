require 'spec_helper'

describe Gws::Tabular::File::ZipExportJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
  let(:allowed_extensions) { %w(.git .png .jpg .jpeg) }
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 10,
      input_type: "single", validation_type: "none", i18n_state: "disabled")
  end
  let!(:column2) do
    create(
      :gws_tabular_column_file_upload_field, cur_site: site, cur_form: form, order: 20,
      name: "Photo1 (#{allowed_extensions.join(" / ")})", allowed_extensions: allowed_extensions)
  end
  let!(:column3) do
    create(
      :gws_tabular_column_file_upload_field, cur_site: site, cur_form: form, order: 30,
      name: "Photo2 (#{allowed_extensions.join(" / ")})", allowed_extensions: allowed_extensions)
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

    form.reload
    release = form.current_release
    expect(release).to be_present
  end

  describe '#perform' do
    let(:attachment_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
    let!(:attachment1_1) { tmp_ss_file(site: site, contents: attachment_path, basename: 'logo.png') }
    let!(:attachment1_2) { tmp_ss_file(site: site, contents: attachment_path, basename: 'logo.png') }
    let!(:attachment2_1) { tmp_ss_file(site: site, contents: attachment_path, basename: 'logo.png') }
    let!(:attachment2_2) { tmp_ss_file(site: site, contents: attachment_path, basename: 'logo.png') }
    let(:file_model) { Gws::Tabular::File[form.current_release] }
    let!(:file_data1) do
      file_model.create!(
        cur_site: site, cur_user: user, cur_space: space, cur_form: form,
        "col_#{column1.id}" => unique_id, "col_#{column2.id}" => attachment1_1, "col_#{column3.id}" => attachment1_2)
    end
    let!(:file_data2) do
      file_model.create!(
        cur_site: site, cur_user: user, cur_space: space, cur_form: form,
        "col_#{column1.id}" => unique_id, "col_#{column2.id}" => attachment2_1, "col_#{column3.id}" => attachment2_2)
    end

    it do
      job = described_class.bind(site_id: site, user_id: user)
      job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, "UTF-8", file_model.all.pluck(:id).map(&:to_s))

      expect(Gws::Job::Log.count).to eq 2
      Gws::Job::Log.all.each do |log|
        expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).not_to include(include('WARN'))
        expect(log.logs).not_to include(include('ERROR'))
      end

      SS::Notification.first.tap do |notice|
        expect(notice.subject).to include I18n.t('gws/share.mailers.compressed.subject')
      end
      expect(SS::Notification.count).to eq 1

      id_path = "#{format("%02d", user.id.to_s.slice(0, 2))}/#{user.id}"
      user_dir = "#{SS::DownloadJobFile.root}/#{id_path}"
      expect(::Dir.exist?(user_dir)).to be_truthy
      physical_filepath = Dir.glob("#{user_dir}/*.zip").first
      expect(physical_filepath).to be_present

      ::Zip::File.open(physical_filepath) do |entries|
        entry_names = entries.map { |entry| entry.name }

        entry_names.uniq!
        expect(entry_names.length).to eq 5
        expect(entry_names).to include("files.csv")
        expect(entry_names).to include("#{file_data1.id}/#{attachment1_1.id}_#{attachment1_1.filename}")
        expect(entry_names).to include("#{file_data1.id}/#{attachment1_2.id}_#{attachment1_2.filename}")
        expect(entry_names).to include("#{file_data2.id}/#{attachment2_1.id}_#{attachment1_1.filename}")
        expect(entry_names).to include("#{file_data2.id}/#{attachment2_2.id}_#{attachment2_2.filename}")

        I18n.with_locale(I18n.default_locale) do
          csv_entry = entries.find_entry("files.csv")
          csv = csv_entry.get_input_stream { |stream| stream.read }
          expect(csv.encoding).to eq Encoding::ASCII_8BIT
          SS::Csv.open(StringIO.new(csv), headers: true) do |csv|
            csv_table = csv.read
            expect(csv_table.length).to eq 2
            csv_table[0].tap do |csv_row|
              expect(csv_row[file_model.t(:id)]).to eq file_data1.id.to_s
              expect(csv_row[SS::Csv.escape_column_name_for_csv(column1.name)]).to be_present
              expected = "#{file_data1.id}/#{attachment1_1.id}_#{attachment1_1.filename}"
              expect(csv_row[SS::Csv.escape_column_name_for_csv(column2.name)]).to eq expected
              expected = "#{file_data1.id}/#{attachment1_2.id}_#{attachment1_2.filename}"
              expect(csv_row[SS::Csv.escape_column_name_for_csv(column3.name)]).to eq expected
            end
            csv_table[1].tap do |csv_row|
              expect(csv_row[file_model.t(:id)]).to eq file_data2.id.to_s
              expect(csv_row[column1.name.gsub('/', '\/')]).to be_present
              expected = "#{file_data2.id}/#{attachment2_1.id}_#{attachment2_1.filename}"
              expect(csv_row[column2.name.gsub('/', '\/')]).to eq expected
              expected = "#{file_data2.id}/#{attachment2_2.id}_#{attachment2_2.filename}"
              expect(csv_row[column3.name.gsub('/', '\/')]).to eq expected
            end
          end
        end
      end
    end
  end
end
