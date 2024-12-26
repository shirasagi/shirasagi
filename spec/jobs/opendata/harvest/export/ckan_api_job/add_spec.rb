require 'spec_helper'

describe Opendata::Harvest::ExportJob, dbscope: :example, ckan: true do
  let!(:site) { cms_site }
  let!(:group) { cms_group }
  let!(:node) { create :opendata_node_dataset, cur_site: site }
  let!(:node_search) { create :opendata_node_search_dataset, cur_site: site }

  let!(:license_file) { Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/ss/logo.png", basename: "spec") }
  let!(:license) { create :opendata_license, cur_site: site, in_file: license_file, name: "cc-by", uid: "cc-by" }

  let!(:exporter) { create(:opendata_harvest_exporter, cur_node: node, url: ckan_url, api_key: api_key) }
  let!(:ckan_url) { "http://localhost:#{SS::CkanSupport.docker_ckan_port}" }
  let!(:api_key) { SS::CkanSupport.docker_ckan_api_key }

  let!(:dataset1) { create :opendata_dataset, cur_site: site, cur_node: node, group_ids: [group.id] }
  let!(:dataset2) { create :opendata_dataset, cur_site: site, cur_node: node, group_ids: [group.id] }
  let(:dataset3) { create :opendata_dataset, cur_site: site, cur_node: node, group_ids: [group.id] }

  let!(:file_path1) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let!(:file_path2) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis-2.csv") }
  let!(:file_path3) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis-3.csv") }

  let(:ckan_package) { Opendata::Harvest::CkanPackage.new(ckan_url) }

  def create_resource(dataset, file_path)
    file = Fs::UploadedFile.create_from_file(file_path)
    filename = file.original_filename
    ext = File.extname(filename).delete(".").upcase

    dataset.resources.create(
      name: unique_id,
      in_file: file,
      license_id: license.id,
      filename: filename,
      format: ext)
  end

  # rubocop:disable Security/Open
  def expect_same_file(file1, file2)
    str1 = URI.open(file1).read
    str2 = URI.open(file2).read
    expect(str1).to eq str2
  end
  # rubocop:enable Security/Open

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

    dataset3
    create_resource(dataset1, file_path3)

    described_class.bind(site_id: site.id).perform_now(exporter_id: exporter.id)
    expect(ckan_package.package_list).to match_array [dataset1.uuid, dataset2.uuid, dataset3.uuid]
    expect(Opendata::Harvest::Exporter::DatasetRelation.count).to eq 3

    resources = ckan_package.package_show(dataset1.uuid)["resources"]
    expect(resources.size).to eq 2
    expect_same_file(resources[0]["url"], file_path1)
    expect_same_file(resources[1]["url"], file_path3)

    resources = ckan_package.package_show(dataset2.uuid)["resources"]
    expect(resources.size).to eq 1
    expect_same_file(resources[0]["url"], file_path2)

    resources = ckan_package.package_show(dataset3.uuid)["resources"]
    expect(resources.size).to eq 0
  end
end
