require 'spec_helper'

describe "opendata_appfiles", dbscope: :example do
  def create_appfile(app, file)
    appfile = app.appfiles.new(text: "aaa", format: "csv")
    appfile.in_file = file
    appfile.save
    appfile
  end

  let(:app) { create(:opendata_app, node: node) }
  let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
  let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
  let(:appfile) { create_appfile(app, file) }

  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_app, name: "opendata_app" }
  let(:index_path) { opendata_app_appfiles_path site.host, node, app_id: app.id }
  let(:new_path) { new_opendata_app_appfile_path site.host, node, app_id: app.id }
  let(:download_path) { opendata_app_appfile_file_path site.host, node, app_id: app.id, appfile_id: appfile.id }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[text]", with: "sample"
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#download" do
      visit download_path
      expect(current_path).not_to eq sns_login_path
    end

  end
end
