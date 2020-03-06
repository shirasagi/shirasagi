require 'spec_helper'

describe Opendata::Harvest::ImportDatasetsJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create(:opendata_node_dataset, name: "datasets") }
  let!(:importer) { create(:opendata_harvest_importer, cur_node: node, api_type: "ckan") }

  let!(:license) { create(:opendata_license, cur_site: site, uid: "cc-by") }

  context "with empty package list" do
    let(:package_list_json) { File.read("spec/fixtures/opendata/harvest/ckan_api/empty_list.json") }
    describe ".perform_later" do
      before do
        stub_request(:get, 'https://source.example.jp/api/action/package_list').
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
    let(:package_list_json) { File.read("spec/fixtures/opendata/harvest/ckan_api/package_list.json") }
    let(:package_show_json) { File.read("spec/fixtures/opendata/harvest/ckan_api/package_show.json") }
    let(:sample_txt) { File.read("spec/fixtures/opendata/harvest/sample.txt") }

    describe ".perform_later" do
      before do
        download_url = ::File.join(
          "http://source.example.jp/dataset",
          "b98c93d4-6461-4927-86c0-162984136d09",
          "resource",
          "c53c15c7-7ef4-4dec-9a42-58f731703c40",
          "download",
          "1490836176.txt"
        )

        stub_request(:get, 'https://source.example.jp/api/action/package_list').
          to_return(body: package_list_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, 'https://source.example.jp/api/action/package_show?id=1490764602').
          to_return(body: package_show_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, download_url).
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
        expect(item.uuid).to eq "b98c93d4-6461-4927-86c0-162984136d09"

        expect(item.resources.count).to eq 1
        resource = item.resources.first
        expect(resource.file.read.include?("opendata harvest")).to be_truthy
        expect(resource.uuid).to eq "c53c15c7-7ef4-4dec-9a42-58f731703c40"
        expect(resource.revision_id).to eq "706b93ce-151f-442a-a8b9-d256614c50db"
        expect(resource.format).to eq "TXT"
      end
    end
  end
end
