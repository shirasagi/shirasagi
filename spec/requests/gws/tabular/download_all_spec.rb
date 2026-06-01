require 'spec_helper'

# Regression test for the GWS 汎用DB (gws/tabular) CSV/ZIP download.
#
# `Gws::Tabular::FilesController#download_all` assigns the `format` parameter
# (csv/zip) selected on the download form to the download param object.
# Previously it used `SS::DownloadParam`, which has no `format` attribute, so
# every submission of the download form raised `ActiveModel::UnknownAttributeError`
# (HTTP 500). See `Gws::Tabular::DownloadParam`.
describe "gws/tabular download_all", type: :request, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site, state: 'public' }
  let!(:form) do
    create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1
  end
  let!(:name_column) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 10,
      input_type: "single", max_length: nil, validation_type: "none",
      index_state: "none", unique_state: "disabled")
  end

  def download_all_path
    download_all_gws_tabular_files_path(site: site, space: space, form: form, view: '-')
  end

  it "downloads CSV/ZIP without error" do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)
    form.reload
    expect(form.current_release).to be_present

    # login
    get sns_auth_token_path(format: :json)
    auth_token = response.parsed_body["auth_token"]
    post sns_login_path(format: :json), params: {
      'authenticity_token' => auth_token, 'item[email]' => user.email, 'item[password]' => ss_pass
    }
    expect(response.status).to eq 204

    # POST with format=csv downloads the CSV (regression: used to be HTTP 500)
    post download_all_path, params: { item: { format: 'csv', encoding: 'UTF-8' } }
    expect(response.status).to eq 200

    post download_all_path, params: { item: { format: 'csv', encoding: 'Shift_JIS' } }
    expect(response.status).to eq 200

    # POST with format=zip enqueues a delayed export and redirects
    post download_all_path, params: { item: { format: 'zip', encoding: 'UTF-8' } }
    expect(response.status).to eq 302
  end
end
