require 'spec_helper'

describe Opendata::Harvest::ImportJob, dbscope: :example, tmpdir: true, ckan: true do
  let!(:site) { cms_site }
  let!(:group) { cms_group }
  let!(:node) { create :opendata_node_dataset, cur_site: site }
  let!(:node_search) { create :opendata_node_search_dataset, cur_site: site }

  let!(:license_file) { Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/ss/logo.png", basename: "spec") }
  let!(:license) { create :opendata_license, cur_site: site, in_file: license_file, name: "cc-by", uid: "cc-by" }

  let!(:exporter) { create(:opendata_harvest_exporter, cur_node: node, url: ckan_url, api_key: api_key) }
  let!(:importer) { create(:opendata_harvest_importer, cur_node: node, source_url: ckan_url, api_type: "ckan") }

  let!(:ckan_url) { "http://localhost:8080" }
  let!(:api_key) { SS::CkanSupport.docker_ckan_api_key }

  let!(:dataset1) { create :opendata_dataset, cur_site: site, cur_node: node, group_ids: [group.id] }
  let!(:dataset2) { create :opendata_dataset, cur_site: site, cur_node: node, group_ids: [group.id] }

  let!(:file_path1) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let!(:file_path2) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis-2.csv") }
  let!(:file_path3) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis-3.csv") }

  let!(:ckan_package) { Opendata::Harvest::CkanPackage.new(ckan_url) }

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
    str1 = URI.open(file1).read
    str2 = URI.open(file2).read
    expect(str1).to eq str2
  end

  before do
    create_resource(dataset1, file_path1)
    create_resource(dataset2, file_path2)
  end

  it do
    # export datasets
    exporter.dataset_purge
    exporter.initialize_organization
    exporter.initialize_group

    expect(ckan_package.package_list).to match_array []
    Opendata::Harvest::ExportJob.bind(site_id: site.id).perform_now(exporter_id: exporter.id)
    expect(ckan_package.package_list).to match_array [dataset1.uuid, dataset2.uuid]

    package1 = ckan_package.package_show(dataset1.uuid)
    expect(package1["title"]).to eq dataset1.name
    expect(package1["resources"].size).to eq 1
    expect(package1["resources"][0]["name"]).to eq dataset1.resources[0].name
    expect_same_file(package1["resources"][0]["url"], dataset1.resources[0].path)

    package2 = ckan_package.package_show(dataset2.uuid)
    expect(package2["title"]).to eq dataset2.name
    expect(package2["resources"][0]["name"]).to eq dataset2.resources[0].name
    expect_same_file(package2["resources"][0]["url"], dataset2.resources[0].path)

    # import datasets
    Opendata::Harvest::ImportJob.bind(site_id: site.id).perform_now(exporter_id: exporter.id)
    expect(Opendata::Dataset.site(site).where(harvest_importer_id: importer.id).count).to eq 2

    imported_dataset1 = Opendata::Dataset.site(site).where(uuid: package1["id"]).first
    expect(imported_dataset1).not_to eq nil
    expect(imported_dataset1.name).to eq package1["title"]
    expect(imported_dataset1.resources.size).to eq 1
    expect(imported_dataset1.resources[0].name).to eq package1["resources"][0]["name"]
    expect_same_file(imported_dataset1.resources[0].path, package1["resources"][0]["url"])

    imported_dataset2 = Opendata::Dataset.site(site).where(uuid: package2["id"]).first
    expect(imported_dataset2).not_to eq nil
    expect(imported_dataset2.name).to eq package2["title"]
    expect(imported_dataset2.resources.size).to eq 1
    expect(imported_dataset2.resources[0].name).to eq package2["resources"][0]["name"]
    expect_same_file(imported_dataset2.resources[0].path, package2["resources"][0]["url"])

    # destroy ckan dataset
    ckan_package.dataset_purge(package1["id"], api_key)
    expect(ckan_package.package_list).to match_array [dataset2.uuid]

    # import datasets
    Opendata::Harvest::ImportJob.bind(site_id: site.id).perform_now(exporter_id: exporter.id)
    expect(Opendata::Dataset.site(site).where(harvest_importer_id: importer.id).count).to eq 1
  end
end
