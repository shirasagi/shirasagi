require 'spec_helper'

describe Gws::Tabular::File::CsvImportJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:role_editor) { create :gws_role, :gws_role_tabular_file_editor, cur_site: site }
  let!(:user1) { create :gws_user, cur_site: site, group_ids: admin.group_ids, gws_role_ids: [ role_editor.id ] }
  let!(:user2) { create :gws_user, cur_site: site, group_ids: admin.group_ids, gws_role_ids: [ role_editor.id ] }
  let!(:space) { create :gws_tabular_space, cur_site: site, cur_user: admin }
  let!(:form) do
    create :gws_tabular_form, cur_site: site, cur_user: admin, cur_space: space, state: 'publishing', revision: 1
  end
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, required: 'optional',
      input_type: "single", validation_type: "none", i18n_state: "disabled")
  end
  let(:column1_value1) { "text-#{unique_id}" }
  let(:column1_value2) { "text-#{unique_id}" }

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: admin).perform_now(form.id.to_s)

    form.reload
    release = form.current_release
    expect(release).to be_present
  end

  describe "#perform" do
    let(:file_model) { Gws::Tabular::File[form.current_release] }

    before do
      # user1 creates one
      file_model.create!(
        cur_site: site, cur_user: user1, cur_space: space, cur_form: form, "col_#{column1.id}" => column1_value1)
    end

    context "overwrite others' created one" do
      let(:csv_filepath) do
        file_model = Gws::Tabular::File[form.current_release]

        I18n.with_locale(I18n.default_locale) do
          tmpfile(extname: ".csv") do |file|
            headers = [ file_model.t(:id), column1.name ]
            file.write SS::Csv::UTF8_BOM
            file.write headers.to_csv

            data_row = [ file_model.all.first.id.to_s, column1_value2 ]
            file.write data_row.to_csv
          end
        end
      end
      let(:ss_csv_file) { tmp_ss_file(user: user2, contents: csv_filepath) }

      it do
        # user2 overwrites one
        job = described_class.bind(site_id: site, user_id: user2)
        job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_csv_file.id)

        expect(Gws::Job::Log.count).to eq 2
        Gws::Job::Log.all.each do |log|
          expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
          expect(log.logs).not_to include(include('WARN'))
          expect(log.logs).not_to include(include('ERROR'))
        end

        file_model = Gws::Tabular::File[form.current_release]
        expect(file_model.all.count).to eq 1
        file_model.all.first.tap do |file_data|
          expect(file_data.site_id).to eq site.id
          expect(file_data.space_id.to_s).to eq space.id.to_s
          expect(file_data.form_id.to_s).to eq form.id.to_s
          expect(file_data.read_tabular_value(column1)).to eq column1_value2
        end
      end
    end
  end
end
