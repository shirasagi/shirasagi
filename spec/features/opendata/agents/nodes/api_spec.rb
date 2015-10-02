require 'spec_helper'

describe "opendata_agents_nodes_api", dbscope: :example, http_server: true do
  # http.default port: 33_190
  http.default doc_root: Rails.root.join("spec", "fixtures", "opendata")

  let!(:node) { create_once :opendata_node_api, name: "opendata_api" }
  let!(:node_area) { create :opendata_node_area }

  let(:package_list_path) { "#{node.url}1/package_list" }
  let(:group_list_path) { "#{node.url}1/group_list" }
  let(:tag_list_path) { "#{node.url}1/tag_list" }
  let(:package_show_path) { "#{node.url}1/package_show" }
  let(:group_show_path) { "#{node.url}1/group_show" }
  let(:tag_show_path) { "#{node.url}1/tag_show" }
  let(:package_search_path) { "#{node.url}1/package_search" }
  let(:resource_search_path) { "#{node.url}1/resource_search" }

  let!(:node_dataset) { create_once :opendata_node_dataset }
  let!(:node_dataset_group_01) { create(:opendata_dataset_group, site: cms_site, categories: [ OpenStruct.new({ _id: 1 }) ]) }
  let!(:node_dataset_group_02) { create(:opendata_dataset_group, site: cms_site, categories: [ OpenStruct.new({ _id: 2 }) ]) }
  let!(:node_search_dataset) { create_once :opendata_node_search_dataset, basename: "dataset/search" }
  let!(:page_dataset_01) do
    create(:opendata_dataset, node: node_dataset, dataset_group_ids: [node_dataset_group_01.id],
                              area_ids: [ node_area.id ], tags: ["TEST_1"])
  end
  let!(:page_dataset_02) do
    create(:opendata_dataset, node: node_dataset, dataset_group_ids: [node_dataset_group_02.id],
                              area_ids: [ node_area.id ], tags: ["TEST_2"])
  end

  let(:dataset_resource_file_path) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let(:dataset_resource) { page_dataset_01.resources.new(attributes_for(:opendata_resource)) }
  let(:dataset_url_resource) { page_dataset_01.url_resources.new(attributes_for(:opendata_url_resource)) }

  let(:license_logo_file) { Fs::UploadedFile.create_from_file(Rails.root.join("spec", "fixtures", "ss", "logo.png")) }
  let(:license) { create(:opendata_license, site: cms_site, file: license_logo_file) }

  before do

    Fs::UploadedFile.create_from_file(dataset_resource_file_path, basename: "spec") do |f|
      dataset_resource.in_file = f
      dataset_resource.license_id = license.id
      dataset_resource.filename = "#{dataset_resource.name}.csv"
      dataset_resource.format = "CSV"
      dataset_resource.save!
    end

    dataset_url_resource.license_id = license.id
    dataset_url_resource.original_url = "http://#{http.addr}:#{http.port}/shift_jis.csv"
    dataset_url_resource.crawl_update = "none"
    dataset_url_resource.save!

  end

  context "api" do

    it "#package_list" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit package_list_path
        expect(status_code).to eq 200

        visit "#{package_list_path}?limit=5"
        expect(status_code).to eq 200

        visit "#{package_list_path}?limit=5&offset=1"
        expect(status_code).to eq 200

        visit "#{package_list_path}?limit=a"
        visit "#{package_list_path}?limit=-5"
        visit "#{package_list_path}?limit=1&offset=b"
        visit "#{package_list_path}?offset=1"
        visit "#{package_list_path}?offset=-1"

      end
    end

    it "#group_list" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit group_list_path
        expect(status_code).to eq 200

        visit "#{group_list_path}?sort=packages"
        expect(status_code).to eq 200

        visit "#{group_list_path}?all_fields=true"
        expect(status_code).to eq 200

        visit "#{group_list_path}?sort=packages&all_fields=true"
        expect(status_code).to eq 200

        visit "#{group_list_path}?sort=resources"

      end
    end

    it "#tag_list" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit tag_list_path
        expect(status_code).to eq 200

        visit "#{tag_list_path}?query=#{page_dataset_01.tags[0]}"
        expect(status_code).to eq 200

        visit "#{tag_list_path}?query=NO_TAG"

      end
    end

    it "#package_show" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit "#{package_show_path}?id=#{page_dataset_01.name}"
        expect(status_code).to eq 200

        visit "#{package_show_path}?id=NO_DATASET"
        visit package_show_path

      end
    end

    it "#tag_show" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit "#{tag_show_path}?id=#{page_dataset_01.tags[0]}"
        expect(status_code).to eq 200

        visit "#{tag_show_path}?id=NO_TAG"
        visit tag_show_path

      end
    end

    it "#group_show" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit "#{group_show_path}?id=#{node_dataset_group_01.id}"
        expect(status_code).to eq 200

        visit "#{group_show_path}?id=NO_DATASET_GROUP"
        visit group_show_path

      end
    end

    it "#package_search" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit package_search_path
        expect(status_code).to eq 200

        visit "#{package_search_path}?q=#{node_dataset.name}"
        expect(status_code).to eq 200

        visit "#{package_search_path}?q=#{node_dataset.name}&start=0"
        expect(status_code).to eq 200

        visit "#{package_search_path}?q=#{node_dataset.name}&rows=5"
        expect(status_code).to eq 200

        visit "#{package_search_path}?q=#{node_dataset.name}&start=0&rows=5"
        expect(status_code).to eq 200

        visit "#{package_search_path}?q=#{node_dataset.name}&start=100&rows=10000"
        expect(status_code).to eq 200

        visit "#{package_search_path}?rows=a"
        visit "#{package_search_path}?rows=-50"
        visit "#{package_search_path}?start=b"
        visit "#{package_search_path}?start=-10"

      end
    end

    it "#resource_search" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit "#{resource_search_path}?query=name:#{dataset_resource.name}"
        expect(status_code).to eq 200

        visit "#{resource_search_path}?query=filename:#{dataset_resource.filename}"
        expect(status_code).to eq 200

        visit "#{resource_search_path}?query=description:#{dataset_resource.text}"
        expect(status_code).to eq 200

        visit "#{resource_search_path}?query=format:#{dataset_resource.format}"
        expect(status_code).to eq 200

        visit "#{resource_search_path}?query=name:#{dataset_resource.name}&offset=0"
        expect(status_code).to eq 200

        visit "#{resource_search_path}?query=name:#{dataset_resource.name}&limit=5"
        expect(status_code).to eq 200

        visit "#{resource_search_path}?query=name:#{dataset_resource.name}&offset=0&limit=5"
        expect(status_code).to eq 200

        visit "#{resource_search_path}?query=name:#{dataset_resource.name}&offset=100&limit=10000"
        expect(status_code).to eq 200

        visit "#{resource_search_path}?query=name:#{dataset_resource.name}&order_by=name"
        expect(status_code).to eq 200

        visit resource_search_path
        visit "#{resource_search_path}?query=name:"
        visit "#{resource_search_path}?query=test:#{dataset_resource.name}"
        visit "#{resource_search_path}?limit=a"
        visit "#{resource_search_path}?limit=-50"
        visit "#{resource_search_path}?offset=b"
        visit "#{resource_search_path}?offset=-10"

      end
    end

  end

end
