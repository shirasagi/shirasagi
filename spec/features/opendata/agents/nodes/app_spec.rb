require 'spec_helper'

describe "opendata_agents_nodes_app", dbscope: :example do
  def create_appfile(app, file, format)
    appfile = app.appfiles.new(text: "aaa", format: format)
    appfile.in_file = file
    appfile.save
    appfile
  end

  let(:site) { cms_site }
  let!(:node) { create_once :opendata_node_app, name: "opendata_agents_nodes_app" }
  let!(:node_member) { create_once :opendata_node_member }
  let!(:node_mypage) { create_once :opendata_node_mypage, filename: "mypage" }

  let!(:node_search) { create :opendata_node_search_app }

  let!(:area) { create_once :opendata_node_area, basename: "opendata_area_1" }
  let!(:app) { create_once :opendata_app, filename: "#{node.filename}/1.html", area_ids: [ area.id ] }
  let!(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
  let!(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
  let!(:appfile) { create_appfile(app, file, "CSV") }

  let!(:node_auth) { create_once :opendata_node_mypage, basename: "opendata/mypage" }

  let(:index_path) { "#{node.url}index.html" }
  let(:download_path) { "#{node.url}#{app.id}/zip" }
  let(:show_point_path) { "#{node.url}#{app.id}/point.html" }
  let(:point_members_path) { "#{node.url}#{app.id}/point/members.html" }
  let(:rss_path) { "#{node.url}rss.xml" }
  let(:show_executed_path) { "#{node.url}#{app.id}/executed/show.html" }
  let(:add_executed_path) { "#{node.url}#{app.id}/executed/add.html" }
  let(:show_ideas_path) { "#{node.url}#{app.id}/ideas/show.html" }
  let(:index_areas_path) { "#{node.url}areas.html" }
  let(:index_tags_path) { "#{node.url}tags.html" }
  let(:index_licenses_path) { "#{node.url}licenses.html" }

  let(:file_index_path) { Rails.root.join("spec", "fixtures", "opendata", "index.html") }
  let(:file_index) { Fs::UploadedFile.create_from_file(file_index_path, basename: "spec") }
  let(:appfile) { create_appfile(app, file_index, "HTML") }
  let(:full_path) { "#{node.url}#{app.id}/full"}
  let(:app_index_path) { "#{node.url}#{app.id}/file_index/#{appfile.id}/app_index.html"}
  let(:text_path) { "#{node.url}#{app.id}/file_text/#{appfile.id}/app_index.html"}

  before do
    login_opendata_member(site, node_auth)
  end

  it "#index" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit index_path
      expect(current_path).to eq index_path
    end
  end

  it "#download" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit download_path
      expect(current_path).to eq download_path
    end
  end

  it "#show_point" do
    visit "http://#{site.domain}#{show_point_path}"
    expect(current_path).to eq show_point_path
  end

  it "#point_members" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit point_members_path
      expect(current_path).to eq point_members_path
    end
  end

  it "#rss" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit rss_path
      expect(current_path).to eq rss_path
    end
  end

  it "#show_executed" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit show_executed_path
      expect(current_path).to eq show_executed_path
    end
  end

  it "#add_executed" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit add_executed_path
      expect(current_path).to eq add_executed_path
    end
  end

  it "#show_ideas" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit show_ideas_path
      expect(current_path).to eq show_ideas_path
    end
  end

  it "#full" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit full_path
      expect(current_path).to eq full_path
    end
  end

  it "#app_index" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit app_index_path
      expect(current_path).to eq app_index_path
    end
  end

  it "#text" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit text_path
      expect(current_path).to eq text_path
    end
  end

  context "app_filter" do
    it "#index_areas" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit index_areas_path
        expect(current_path).to eq index_areas_path
      end
    end

    it "#index_tags" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit index_tags_path
        expect(current_path).to eq index_tags_path
      end
    end

    it "#index_licenses" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit index_licenses_path
        expect(current_path).to eq index_licenses_path
      end
    end
  end

end
