require 'spec_helper'

describe "opendata_appscripts" do
  def create_appfile(app, file)
    appfile = app.appfiles.new(text: "aaa", format: "html")
    appfile.in_file = file
    appfile.save
    appfile
  end

  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_app, name: "opendata_app" }
  let(:app) { create(:opendata_app, node: node) }
  let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "index.html") }
  let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
  let(:appfile) { create_appfile(app, file) }

  let(:index_path) { "/app/#{app.id}/application/index.html"}
  let(:full_path) { "/app/#{app.id}/full"}
  let(:text_path) { "/text/#{app.id}/appfile/index.html"}

  it "#index" do
    visit index_path
    expect(current_path).to eq index_path
  end

  it "#full" do
    visit full_path
    expect(current_path).to eq full_path
  end

  it "#text" do
    visit text_path
    expect(current_path).to eq text_path
  end
end
