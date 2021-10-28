require 'spec_helper'

describe Opendata::Harvest::ImportDatasetsJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create(:cms_layout) }

  let!(:node_area) { create_once :opendata_node_area }
  let!(:node_category) { create_once :opendata_node_dataset_category }
  let!(:node_search) { create_once :opendata_node_search_dataset, filename: "dataset/search" }
  let!(:node) { create(:opendata_node_dataset, name: "datasets") }

  let!(:license) { create(:opendata_license, cur_site: site, uid: "cc-by", name: "表示（CC BY）") }

  context "with empty datasets" do
    let!(:importer) { create(:opendata_harvest_importer, cur_node: node, source_url: "http://source.example.jp", api_type: "shirasagi_scraper") }

    let(:search_html) { File.read("spec/fixtures/opendata/harvest/shirasagi_scraper/empty_search.html")  }
    describe "#perform" do
      before do
        stub_request(:get, "http://source.example.jp/dataset/search/index.p1.html").
          to_return(body: search_html, status: 200, headers: { 'Content-Type' => 'text/html' })

        job = described_class.bind(site_id: site)
        expect { job.perform_now(importer.id) }.to output(include("dataset_urls 0\n")).to_stdout
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(include("import from http://source.example.jp"))
        expect(log.logs).to include(include("dataset_urls 0"))
        expect(Opendata::Dataset.count).to eq 0
      end
    end
  end

  context "with datasets html" do
    let!(:importer) { create(:opendata_harvest_importer, cur_node: node, source_url: "https://source.example.jp", api_type: "shirasagi_scraper") }

    let(:search1_html) { File.read("spec/fixtures/opendata/harvest/shirasagi_scraper/search1.html") }
    let(:search2_html) { File.read("spec/fixtures/opendata/harvest/shirasagi_scraper/search2.html") }
    let(:dataset1_html) { File.read("spec/fixtures/opendata/harvest/shirasagi_scraper/dataset1.html") }
    let(:dataset2_html) { File.read("spec/fixtures/opendata/harvest/shirasagi_scraper/dataset2.html") }
    let(:dataset3_html) { File.read("spec/fixtures/opendata/harvest/shirasagi_scraper/dataset3.html") }
    let(:dataset4_html) { File.read("spec/fixtures/opendata/harvest/shirasagi_scraper/dataset4.html") }
    let(:dataset5_html) { File.read("spec/fixtures/opendata/harvest/shirasagi_scraper/dataset5.html") }
    let(:sample_csv) { File.read("spec/fixtures/opendata/harvest/shirasagi_scraper/sample.csv") }
    let(:sample2_xlsx) { File.read("spec/fixtures/opendata/harvest/shirasagi_scraper/sample2.xlsx") }
    let(:sample_txt) { File.read("spec/fixtures/opendata/harvest/shirasagi_scraper/sample.txt") }

    describe "#perform" do
      before do
        stub_request(:get, 'https://source.example.jp/dataset/search/index.p1.html').
          to_return(body: search1_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, 'https://source.example.jp/dataset/search/index.p2.html').
            to_return(body: search2_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, 'https://source.example.jp/dataset/1.html').
          to_return(body: dataset1_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, 'https://source.example.jp/dataset/2.html').
          to_return(body: dataset2_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, 'https://source.example.jp/dataset/3.html').
          to_return(body: dataset3_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, 'https://source.example.jp/dataset/4.html').
          to_return(body: dataset4_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, 'https://source.example.jp/dataset/5.html').
          to_return(body: dataset5_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, 'https://source.example.jp/fs/1/6/5/_/sample.txt').
          to_return(body: sample_txt, status: 200, headers: { 'Content-Type' => 'text/csv' })
        stub_request(:get, 'https://source.example.jp/fs/1/6/6/_/sample.csv').
          to_return(body: sample_csv, status: 200, headers: { 'Content-Type' => 'text/csv' })
        stub_request(:get, 'https://source.example.jp/fs/1/6/7/_/sample2.xlsx').
          to_return(body: sample2_xlsx, status: 200, headers: { 'Content-Type' => 'application/octet-stream' })

        job = described_class.bind(site_id: site)
        expect { job.perform_now(importer.id) }.to output(include("dataset_urls 5\n")).to_stdout
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(include("import from https://source.example.jp"))
        expect(Opendata::Dataset.count).to eq 5
        expect(Opendata::Dataset.all.map { |item| item.resources.to_a }.flatten.size).to eq 3
      end
    end
  end

  def create_dataset(*paths)
    dataset = create(:opendata_dataset, cur_node: node)
    dataset.layout_id = layout.id
    paths.each do |path|
      resource = Opendata::Resource.new(attributes_for(:opendata_resource))
      resource.in_file = Fs::UploadedFile.create_from_file(path, basename: "spec")
      resource.license = license
      dataset.resources << resource
    end
    dataset.save!
    dataset
  end

  context "with datasets" do
    let!(:importer) { create(:opendata_harvest_importer, cur_node: node, source_url: "http://#{site.domain}", api_type: "shirasagi_scraper") }

    let(:search1_url) { ::File.join(node_search.full_url, "index.p1.html") }
    let(:search2_url) { ::File.join(node_search.full_url, "index.p2.html") }

    let(:sample_csv) { "spec/fixtures/opendata/harvest/shirasagi_scraper/sample.csv" }
    let(:sample2_xlsx) { "spec/fixtures/opendata/harvest/shirasagi_scraper/sample2.xlsx" }
    let(:sample_txt) { "spec/fixtures/opendata/harvest/shirasagi_scraper/sample.txt" }

    describe "#perform" do
      before do
        @dataset1 = create_dataset(sample_txt)
        @dataset2 = create_dataset
        @dataset3 = create_dataset
        @dataset4 = create_dataset
        @dataset5 = create_dataset(sample_csv, sample2_xlsx)

        Capybara.app_host = "http://#{site.domain}"

        Fs.rm_rf node.path
      end

      it do
        visit search1_url
        expect(page).to have_css(".opendata-search-datasets.pages h2 a", text: @dataset1.name)
        expect(page).to have_css(".opendata-search-datasets.pages h2 a", text: @dataset2.name)
        expect(page).to have_css(".opendata-search-datasets.pages h2 a", text: @dataset3.name)
        expect(page).to have_css(".opendata-search-datasets.pages h2 a", text: @dataset4.name)
        expect(page).to have_css(".opendata-search-datasets.pages h2 a", text: @dataset5.name)
        @search1_html = "<div>" + page.html + "</div>"

        click_on @dataset1.name
        expect(page).to have_css("h1", text: @dataset1.name)
        @dataset1_html = "<div>" + page.html + "</div>"
        visit node_search.url

        click_on @dataset2.name
        expect(page).to have_css("h1", text: @dataset2.name)
        @dataset2_html = "<div>" + page.html + "</div>"
        visit node_search.url

        click_on @dataset3.name
        expect(page).to have_css("h1", text: @dataset3.name)
        @dataset3_html = "<div>" + page.html + "</div>"
        visit node_search.url

        click_on @dataset4.name
        expect(page).to have_css("h1", text: @dataset4.name)
        @dataset4_html = "<div>" + page.html + "</div>"
        visit node_search.url

        click_on @dataset5.name
        expect(page).to have_css("h1", text: @dataset5.name)
        @dataset5_html = "<div>" + page.html + "</div>"
        visit node_search.url

        visit search2_url
        @search2_html = "<div>" + page.html + "</div>"

        stub_request(:get, search1_url).to_return(body: @search1_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, search2_url).to_return(body: @search2_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, @dataset1.full_url).to_return(body: @dataset1_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, @dataset2.full_url).to_return(body: @dataset2_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, @dataset3.full_url).to_return(body: @dataset3_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, @dataset4.full_url).to_return(body: @dataset4_html, status: 200, headers: { 'Content-Type' => 'text/html' })
        stub_request(:get, @dataset5.full_url).to_return(body: @dataset5_html, status: 200, headers: { 'Content-Type' => 'text/html' })

        file1_url = ::File.join(site.full_url, @dataset1.resources[0].file.url)
        file2_url = ::File.join(site.full_url, @dataset5.resources[0].file.url)
        file3_url = ::File.join(site.full_url, @dataset5.resources[1].file.url)

        stub_request(:get, file1_url).to_return(body: ::File.read(sample_txt), status: 200, headers: { 'Content-Type' => 'text/csv' })
        stub_request(:get, file2_url).to_return(body: ::File.read(sample_csv), status: 200, headers: { 'Content-Type' => 'text/csv' })
        stub_request(:get, file3_url).to_return(body: ::File.read(sample2_xlsx), status: 200, headers: { 'Content-Type' => 'application/octet-stream' })

        Opendata::Dataset.destroy_all

        job = described_class.bind(site_id: site)
        expect { job.perform_now(importer.id) }.to output(include("dataset_urls 5\n")).to_stdout

        log = Job::Log.first
        expect(log.logs).to include(include("import from http://#{site.domain}"))
        expect(Opendata::Dataset.count).to eq 5
        expect(Opendata::Dataset.all.map { |item| item.resources.to_a }.flatten.size).to eq 3
      end
    end
  end
end
