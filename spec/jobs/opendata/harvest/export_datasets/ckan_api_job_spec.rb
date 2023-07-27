require 'spec_helper'

describe Opendata::Harvest::ExportDatasetsJob, dbscope: :example, ckan: true do
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
  let!(:dataset3) { create :opendata_dataset, cur_site: site, cur_node: node, group_ids: [group.id] }
  let!(:dataset4) { create :opendata_dataset, cur_site: site, cur_node: node, group_ids: [group.id] }
  let!(:dataset5) { create :opendata_dataset, cur_site: site, cur_node: node, group_ids: [group.id] }

  let!(:file_path1) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let!(:file_path2) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis-2.csv") }
  let!(:file_path3) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis-3.csv") }
  let!(:file_path4) { Rails.root.join("spec", "fixtures", "opendata", "resource.pdf") }

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

  before do
    create_resource(dataset1, file_path1)
    create_resource(dataset2, file_path2)
    create_resource(dataset3, file_path3)
    create_resource(dataset4, file_path4)
  end

  it do
    exporter.initialize_organization
    exporter.initialize_group

    expect(ckan_package.package_list).to match_array []
    ::Opendata::Harvest::HarvestDatasetsJob.bind(site_id: site.id).perform_now(exporter_id: exporter.id)
    expect(ckan_package.package_list).to match_array [
      dataset1.uuid,
      dataset2.uuid,
      dataset3.uuid,
      dataset4.uuid,
      dataset5.uuid]
  end
end
