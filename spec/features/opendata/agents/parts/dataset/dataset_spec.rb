require 'spec_helper'

describe "opendata_agents_nodes_dataset", dbscope: :example do
  let(:site) { cms_site }
  let!(:node_category) { create :opendata_node_category, basename: "bunya/kurashi" }
  let!(:node_search_dataset) { create :opendata_node_search_dataset, basename: "dataset/search" }
  let!(:node_search_dataset_group) { create :opendata_node_search_dataset_group }
  let!(:node_dataset) { create(:opendata_node_dataset) }
  let!(:page_dataset) { create(:opendata_dataset, node: node_dataset) }
  let(:part) { create :opendata_part_dataset, sort: 'attention' }
  let(:index_url) { ::URI.parse "http://#{site.domain}#{part.url}" }

  describe "#index" do
    it do
      visit index_url.to_s
      expect(status_code).to eq 200
      expect(current_path).to eq index_url.path
      within "div.pages" do
        expect(page).to have_content(page_dataset.name)
      end
      expect(page).not_to have_css("nav.feed")
    end
  end
end
