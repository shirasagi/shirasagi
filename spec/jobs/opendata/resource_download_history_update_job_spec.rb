require 'spec_helper'

describe Opendata::ResourceDownloadHistoryUpdateJob, dbscope: :example do
  let(:site) { cms_site }
  let(:dataset_node) { create :opendata_node_dataset, cur_site: site }
  let(:area_node) { create :opendata_node_area, cur_site: site }
  let(:category_node) { create :opendata_node_category, cur_site: site }
  let(:estat_category_node) { create :opendata_node_estat_category, cur_site: site }
  let!(:search_dataset) { create :opendata_node_search_dataset, cur_site: site }
  let(:dataset) do
    create(:opendata_dataset, cur_site: site, cur_node: dataset_node, area_ids: [area_node.id],
           category_ids: [category_node.id], estat_category_ids: [estat_category_node.id])
  end
  let(:resource_file_path) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let(:license) { create(:opendata_license, cur_site: site) }
  let(:resource) { dataset.resources.new(attributes_for(:opendata_resource)) }
  let(:item) do
    create(:opendata_resource_download_history_invalid, cur_site: site, dataset_id: dataset.id, resource_id: resource.id)
  end

  before do
    Fs::UploadedFile.create_from_file(resource_file_path, basename: "spec") do |f|
      resource.in_file = f
      resource.license_id = license.id
      resource.save!
    end

    item.unset(:site_id)
  end

  it do
    described_class.perform_now

    expect(Job::Log.count).to eq 1
    Job::Log.first.tap do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end

    item.reload
    expect(item.site_id).to eq site.id
    expect(item.dataset_name).to eq dataset.name
    expect(item.dataset_areas).to eq dataset.areas.order_by(order: 1).pluck(:name)
    expect(item.dataset_categories).to eq dataset.categories.order_by(order: 1).pluck(:name)
    expect(item.dataset_estat_categories).to eq dataset.estat_categories.order_by(order: 1).pluck(:name)
    expect(item.full_url).to eq dataset.full_url
    expect(item.resource_name).to eq resource.name
    expect(item.resource_filename).to eq resource.filename
    expect(item.resource_source_url).to eq resource.source_url
  end
end
