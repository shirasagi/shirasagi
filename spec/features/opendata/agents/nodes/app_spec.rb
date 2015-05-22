require 'spec_helper'

describe "opendata_agents_nodes_app", dbscope: :example do
  def create_appfile(app, file)
    appfile = app.appfiles.new(text: "aaa", format: "csv")
    appfile.in_file = file
    appfile.save
    appfile
  end
  before do
    create_once :opendata_node_search_app, basename: "app/search"
  end
  let(:area) { create_once :opendata_node_area, basename: "opendata_area_1" }
  let(:node) { create_once :opendata_node_app, name: "opendata_agents_nodes_app" }
  let(:app) { create_once :opendata_app, filename: "#{node.filename}/1.html", area_ids: [ area.id ] }
  let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
  let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
  let(:appfile) { create_appfile(app, file) }
  let(:site) { cms_site }
  let(:index_path) { "#{node.url}index.html" }
  let(:download_path) { "#{node.url}#{app.id}/zip" }
  let(:show_point_path) { "#{node.url}#{app.id}/point.html" }
  let(:add_point_path) { "#{node.url}#{app.id}/point.html" }
  let(:rss_path) { "#{node.url}rss.xml" }
  let(:show_executed_path) { "#{node.url}#{app.id}/executed/show.html" }
  let(:show_ideas_path) { "#{node.url}#{app.id}/ideas/show.html" }
  let(:index_areas_path) { "#{node.url}areas.html" }
  let(:index_tags_path) { "#{node.url}tags.html" }
  let(:index_licenses_path) { "#{node.url}licenses.html" }

  it "#index" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", index_path)
      visit index_path
      expect(current_path).to eq index_path
    end
  end

  it "#download" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", download_path)
      visit download_path
      expect(current_path).to eq download_path
    end
  end

  it "#show_point" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", show_point_path)
      session.env("method", "POST")
      visit show_point_path
      expect(current_path).to eq show_point_path
    end
  end

  it "#rss" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", rss_path)
      visit rss_path
      expect(current_path).to eq rss_path
    end
  end

  it "#show_executed" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", show_executed_path)
      session.env("method", "POST")
      visit show_executed_path
      expect(current_path).to eq show_executed_path
    end
  end

  it "#add_executed" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", add_executed_path)
      visit add_executed_path
      expect(current_path).to eq add_executed_path
    end
  end

  it "#show_ideas" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", show_ideas_path)
      visit show_ideas_path
      expect(current_path).to eq show_ideas_path
    end
  end

  context "app_filter" do
    it "#index_areas" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        session.env("REQUEST_PATH", index_areas_path)
        visit index_areas_path
        expect(current_path).to eq index_areas_path
      end
    end

    it "#index_tags" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        session.env("REQUEST_PATH", index_tags_path)
        visit index_tags_path
        expect(current_path).to eq index_tags_path
      end
    end

    it "#index_licenses" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        session.env("REQUEST_PATH", index_licenses_path)
        visit index_licenses_path
        expect(current_path).to eq index_licenses_path
      end
    end
  end

end
