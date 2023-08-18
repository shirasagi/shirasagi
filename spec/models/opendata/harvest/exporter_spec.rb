require 'spec_helper'

describe Opendata::Harvest::Exporter, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create(:opendata_node_dataset, name: "datasets") }
  let!(:node_search) { create_once :opendata_node_search_dataset }
  let!(:dataset) { create(:opendata_dataset, cur_node: node) }

  let!(:license1) { create(:opendata_license, cur_site: site, uid: "cc-by") }
  let!(:license2) { create(:opendata_license, cur_site: site, uid: "cc-by-sa") }

  let!(:cate) { create(:opendata_node_category) }
  let!(:estat_cate) { create(:opendata_node_estat_category) }
  let!(:area) { create(:opendata_node_area) }

  let!(:item) do
    create(:opendata_harvest_exporter, cur_node: node)
  end

  it "#api_type_options" do
    expect(item.api_type_options).not_to be_nil
  end
end
