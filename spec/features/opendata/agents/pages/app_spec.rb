require 'spec_helper'

describe "opendata_agents_pages_app", dbscope: :example do
  def create_appfile(app, file, format)
    appfile = app.appfiles.new(text: "index", format: format)
    appfile.in_file = file
    appfile.save
    appfile
  end

  let(:site) { cms_site }
  let!(:node) { create_once :opendata_node_app, name: "opendata_app" }
  let!(:node_member) { create_once :opendata_node_member }
  let!(:node_mypage) { create_once :opendata_node_mypage, filename: "mypage" }
  let!(:category) { create_once :opendata_node_category, basename: "opendata_category1" }
  let!(:area) { create_once :opendata_node_area, basename: "opendata_area_1" }
  let!(:node_search) { create :opendata_node_search_app }

  let!(:node_auth) { create_once :opendata_node_mypage, basename: "opendata/mypage" }

  before do
    login_opendata_member(site, node_auth)
  end

  context "appurl" do
    let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
    let(:node_ds) { create_once :opendata_node_dataset, basename: "opendata_dataset1" }
    let(:dataset) { create(:opendata_dataset, node: node_ds) }
    let(:appurl) do
      create_once :opendata_app,
                  filename: "#{node.filename}/#{unique_id}.html",
                  appurl: "http://dev.ouropendata.jp",
                  category_ids: [ category.id ],
                  area_ids: [ area.id ],
                  dataset_ids: [ dataset.id ]
    end
    let(:appurl_path) { "#{appurl.url}" }

    it "#index" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit appurl_path
        expect(current_path).to eq appurl_path
      end
    end

  end

  context "html" do
    let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "index.html") }
    let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
    let(:jsfile_path) { Rails.root.join("spec", "fixtures", "opendata", "test.js") }
    let(:jsfile) { Fs::UploadedFile.create_from_file(jsfile_path, basename: "spec") }
    let(:cssfile_path) { Rails.root.join("spec", "fixtures", "opendata", "test.css") }
    let(:cssfile) { Fs::UploadedFile.create_from_file(cssfile_path, basename: "spec") }
    let(:html) do
      create_once :opendata_app,
                  filename: "#{node.filename}/#{unique_id}.html"
    end
    let(:html_path) { "#{html.url}" }
    before do
      create_appfile(html, file, "HTML")
      create_appfile(html, jsfile, "JS")
      create_appfile(html, cssfile, "CSS")
    end

    it "#index" do
      visit "http://#{site.domain}#{html_path}"
      expect(current_path).to eq html_path
    end
  end
end
