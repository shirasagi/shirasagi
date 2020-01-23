require 'spec_helper'

describe Opendata::Harvest::ImportDatasetsJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create(:opendata_node_dataset, name: "datasets") }
  let!(:importer) { create(:opendata_harvest_importer, cur_node: node, api_type: "shirasagi_api") }

  let!(:license) { create(:opendata_license, cur_site: site, uid: "cc-by") }

  context "with empty package list" do
    let(:package_list_json) { File.read("spec/fixtures/opendata/harvest/shirasagi_api/empty_list.json") }
    describe ".perform_later" do
      before do
        stub_request(:get, 'https://source.example.jp/api/package_list').
          to_return(body: package_list_json, status: 200, headers: { 'Content-Type' => 'application/json' })

        perform_enqueued_jobs do
          described_class.bind(site_id: site).perform_later(importer.id)
        end
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))
      end
    end
  end

  context "with package list" do
    let(:package_list_json) { File.read("spec/fixtures/opendata/harvest/shirasagi_api/package_list.json") }
    let(:package_show_json) { File.read("spec/fixtures/opendata/harvest/shirasagi_api/package_show.json") }
    let(:sample_txt) { File.read("spec/fixtures/opendata/harvest/sample.txt") }

    describe ".perform_later" do
      before do
        stub_request(:get, 'https://source.example.jp/api/package_list').
            to_return(body: package_list_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, 'https://source.example.jp/api/package_show?id=29b8d70d-1070-4e91-ad38-b5c181494fd6').
            to_return(body: package_show_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, 'https://source.example.jp/dataset/1/resource/1/sample.txt').
            to_return(body: sample_txt, status: 200, headers: { 'Content-Type' => 'application/text' })
        stub_request(:get, 'https://source.example.jp/fs/1/2/3/_/sample.txt').
            to_return(body: sample_txt, status: 200, headers: { 'Content-Type' => 'application/text' })

        perform_enqueued_jobs do
          described_class.bind(site_id: site).perform_later(importer.id)
        end
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))

        expect(Opendata::Dataset.all.count).to eq 1
        item = Opendata::Dataset.first
        expect(item.uuid).to eq "29b8d70d-1070-4e91-ad38-b5c181494fd6"

        expect(item.resources.count).to eq 1
        resource = item.resources.first
        expect(resource.file.read.include?("opendata harvest")).to be_truthy
        expect(resource.uuid).to eq "a3f340e2-fd2c-4b4c-b0d0-06c3170045a7"
        expect(resource.revision_id).to eq "b815875b-a428-4406-a93c-904dba2c0981"
        expect(resource.format).to eq "TXT"
      end
    end
  end
end
