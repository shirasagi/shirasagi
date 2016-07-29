require 'spec_helper'

describe "opendata_agents_nodes_appfile", dbscope: :example do
  def create_appfile(app, file, format)
    appfile = app.appfiles.new(text: "aaa", format: format)
    appfile.in_file = file
    appfile.save
    appfile
  end
  let(:site) { cms_site }
  let(:node) { create :opendata_node_app, name: "opendata_agents_nodes_appfile" }
  let(:app) { create :opendata_app, cur_node: node }
  let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
  let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
  let(:appfile) { create_appfile(app, file, "CSV") }
  let(:file_json_path) { Rails.root.join("spec", "fixtures", "opendata", "test.json") }
  let(:file_json) { Fs::UploadedFile.create_from_file(file_json_path, basename: "spec") }
  let(:json) { create_appfile(app, file_json, "JSON") }
  let(:index_path) { appfile.url.sub(/#{appfile.filename}$/, "") }
  let(:content_path) { appfile.url.sub(/#{appfile.filename}$/, "content.html") }
  let(:json_path) { json.url.sub(/#{json.filename}$/, "json.html") }
  let(:download_path) { appfile.url }
  let!(:node_search) { create :opendata_node_search_app }

  it "#index" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit index_path
      expect(current_path).to eq app.url
    end
  end

  it "#content" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit content_path
      expect(current_path).to eq content_path
    end
  end

  it "#json" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit json_path
      expect(current_path).to eq json_path
    end
  end

  it "#download" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit download_path
      expect(current_path).to eq download_path
    end
  end

end
