require 'spec_helper'

describe Opendata::Harvest::ExportJob, dbscope: :example, ckan: true do
  let!(:site) { cms_site }
  let!(:group) { cms_group }
  let!(:node) { create :opendata_node_dataset, cur_site: site }
  let!(:node_search) { create :opendata_node_search_dataset, cur_site: site }

  let!(:license_file) { Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/ss/logo.png", basename: "spec") }
  let!(:license) { create :opendata_license, cur_site: site, in_file: license_file }

  let!(:exporter) { create(:opendata_harvest_exporter, cur_node: node, url: ckan_url, api_key: api_key) }
  let!(:ckan_url) { "http://localhost:8080" }
  let!(:api_key) { SS::CkanSupport.docker_ckan_api_key }

  let!(:dataset1) { create :opendata_dataset, cur_site: site, cur_node: node, group_ids: [group.id] }
  let!(:dataset2) { create :opendata_dataset, cur_site: site, cur_node: node, group_ids: [group.id] }

  let!(:file_path1) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let!(:file_path2) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis-2.csv") }

  let(:ckan_package) { Opendata::Harvest::CkanPackage.new(ckan_url) }

  def create_resource(dataset, file_path)
    file = Fs::UploadedFile.create_from_file(file_path)
    filename = file.original_filename
    ext = ::File.extname(filename).delete(".").upcase

    dataset.resources.create(
      name: unique_id,
      in_file: file,
      license_id: license.id,
      filename: filename,
      format: ext)
  end

  def expect_same_file(file1, file2)
    expect(URI.open(file1, "rb").read).to eq URI.open(file2, "rb").read
  end

  before do
    create_resource(dataset1, file_path1)
    create_resource(dataset2, file_path2)
  end

  it do
    exporter.dataset_purge
    exporter.initialize_organization
    exporter.initialize_group

    expect(ckan_package.package_list).to match_array []
    described_class.bind(site_id: site.id).perform_now(exporter_id: exporter.id)
    expect(ckan_package.package_list).to match_array [dataset1.uuid, dataset2.uuid]
    expect(Opendata::Harvest::Exporter::DatasetRelation.count).to eq 2

    resources = ckan_package.package_show(dataset1.uuid)["resources"]
    expect(resources.size).to eq 1
    expect_same_file(resources[0]["url"], file_path1)

    resources = ckan_package.package_show(dataset2.uuid)["resources"]
    expect(resources.size).to eq 1
    expect_same_file(resources[0]["url"], file_path2)

    dataset2.destroy

    described_class.bind(site_id: site.id).perform_now(exporter_id: exporter.id)
    expect(ckan_package.package_list).to match_array [dataset1.uuid]
    expect(Opendata::Harvest::Exporter::DatasetRelation.count).to eq 1

    resources = ckan_package.package_show(dataset1.uuid)["resources"]
    expect(resources.size).to eq 1
    expect_same_file(resources[0]["url"], file_path1)

    dataset1.destroy

    described_class.bind(site_id: site.id).perform_now(exporter_id: exporter.id)
    expect(ckan_package.package_list).to match_array []
    expect(Opendata::Harvest::Exporter::DatasetRelation.count).to eq 0
  end
end
