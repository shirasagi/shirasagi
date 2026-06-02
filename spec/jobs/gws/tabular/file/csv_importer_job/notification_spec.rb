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
      validation_type: "none", i18n_state: 'disabled')
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

    form.reload
    expect(form.current_release).to be_present
  end

  let(:file_model) { Gws::Tabular::File[form.current_release] }

  let(:csv_filepath) do
    I18n.with_locale(I18n.default_locale) do
      tmpfile(extname: ".csv") do |file|
        headers = [ file_model.t(:id), column1.name ]
        file.write SS::Csv::UTF8_BOM
        file.write headers.to_csv
        file.write [ BSON::ObjectId.new.to_s, "text-#{unique_id}" ].to_csv
      end
    end
  end
  let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

  it "通知の件名がサービスオブジェクトではなくメッセージになる" do
    job = described_class.bind(site_id: site, user_id: user)
    job.perform_now(space.id.to_s, form.id.to_s, form.current_release.id.to_s, ss_csv_file.id)

    expect(SS::Notification.count).to eq 1
    notice = SS::Notification.first
    expect(notice.subject).not_to include("NotificationSubjectService")
    expect(notice.subject).to eq I18n.t("gws_notification.gws/tabular/file.import_succeeded", form: form.i18n_name)
  end
end
