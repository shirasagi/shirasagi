require 'spec_helper'

describe "opendata_agents_nodes_dataset_group", dbscope: :example do
  let(:site) { cms_site }
  let!(:category) { create :opendata_node_category, basename: "bunya/kurashi" }
  let!(:dataset_group) { create :opendata_dataset_group, categories: [ category ] }
  let(:node) { create :opendata_node_dataset_category }
  let(:part) { create :opendata_part_dataset_group, cur_node: node }
  before do
    create :opendata_node_search_dataset, basename: "dataset/search"
    create :opendata_node_search_dataset_group
  end

  let(:index_url) { ::URI.parse "http://#{site.domain}#{part.url}" }

  describe "#index" do
    it do
      visit "#{index_url}?ref=/#{node.filename}"
      expect(status_code).to eq 200
      expect(current_path).to eq index_url.path
      expect(page).to have_link dataset_group.name
    end
  end
end
