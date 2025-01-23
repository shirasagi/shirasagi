require 'spec_helper'

describe "opendata_agents_nodes_dataset", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  # let(:area) { create_once :opendata_node_area, filename: "opendata_area_1" }
  let!(:node_dataset) { create_once :opendata_node_dataset }
  let!(:node_area) { create :opendata_node_area }
  let!(:node_search_dataset) { create_once :opendata_node_search_dataset, filename: "dataset/search" }
  let!(:page_dataset) { create(:opendata_dataset, cur_node: node_dataset, area_ids: [ node_area.id ]) }
  let!(:node_dataset_category) { create_once :opendata_node_dataset_category }
  let!(:node_category) { create :opendata_node_category, filename: "bunya/kurashi" }
  let(:dataset_resource_file_path) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let(:dataset_resource) { page_dataset.resources.new(attributes_for(:opendata_resource)) }
  let(:license) { create(:opendata_license, cur_site: site) }
  let(:node) { create :opendata_node_search_dataset_group }
  let(:index_url) { ::URI.parse "http://#{site.domain}#{node.url}" }

  before do
    Fs::UploadedFile.create_from_file(dataset_resource_file_path, basename: "spec") do |f|
      dataset_resource.in_file = f
      dataset_resource.license_id = license.id
      dataset_resource.save!
    end
  end

  it "index" do
    visit index_url
    expect(current_path).to eq index_url.path
    expect(status_code).to eq 200
    within "form.opendata-search-groups-form" do
      fill_in "s[name]", with: dataset_resource.name
      select node_category.name, from: 's[category_id]'
      click_button I18n.t('ss.buttons.search')
    end
    expect(status_code).to eq 200
  end
end
