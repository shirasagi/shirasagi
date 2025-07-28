require 'spec_helper'

describe Gws::Tabular::File, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
  let!(:column1) do
    create(:gws_tabular_column_file_upload_field, cur_site: site, cur_form: form, required: 'optional')
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

  context "with actual value" do
    let(:file_model) { Gws::Tabular::File[form.current_release] }
    let(:attachment_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
    let!(:attachment) { tmp_ss_file(site: site, contents: attachment_path, basename: 'logo.png') }
    let!(:file_data) do
      file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form, "col_#{column1.id}" => attachment)
    end

    it do
      text = file_data.read_csv_value(column1)
      expect(text).to eq "#{file_data.id}/#{attachment.id}_#{attachment.filename}"
    end
  end

  context "with nil value" do
    let(:file_model) { Gws::Tabular::File[form.current_release] }
    let!(:file_data) do
      file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form)
    end

    it do
      text = file_data.read_csv_value(column1)
      expect(text).to be_blank
    end
  end
end
