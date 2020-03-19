require 'spec_helper'

describe "opendata_agents_nodes_url_resource", dbscope: :example, http_server: true,
             doc_root: Rails.root.join("spec", "fixtures", "opendata") do

  def create_url_resource(dataset, license, original_url)
    url_resource = dataset.url_resources.new(
      name: "test",
      text: "text",
      license_id: license.id,
      original_url: original_url,
      crawl_update: "none")
    url_resource.save!
    url_resource
  end

  let(:site) { cms_site }
  let!(:node_search) { create :opendata_node_search_dataset }

  let!(:node) { create :opendata_node_dataset, name: "opendata_agents_nodes_url_resource" }
  let!(:dataset) { create :opendata_dataset, cur_node: node, filename: "1.html" }

  let!(:license) { create(:opendata_license, cur_site: site) }
  let!(:original_url) do
    "http://www.esri.cao.go.jp/jp/sna/data/data_list/sokuhou/files/2014/qe143_2/__icsFiles/afieldfile/2014/12/09/gaku-mg1432.csv"
  end
  let!(:url_resource) { create_url_resource(dataset, license, original_url) }
  let(:download_path) { url_resource.download_url }

  it "#download" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit download_path
      expect(current_path).to eq download_path
    end
  end
end
