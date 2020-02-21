require 'spec_helper'

describe "opendata_agents_nodes_dataset_category", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node_category_folder) { create_once :cms_node_node, filename: "category" }
  let(:node_dataset) { create_once :opendata_node_dataset }
  let(:node) do
    create_once(
      :opendata_node_dataset_category,
      filename: "#{node_dataset.filename}/#{node_category_folder.filename}",
      depth: node_dataset.depth + 1)
  end
  before do
    create_once(
      :opendata_node_category,
      filename: "#{node_category_folder.filename}/kurashi",
      depth: node_category_folder.depth + 1)
    create_once(:opendata_node_search_dataset, filename: "dataset/search")
  end

  let(:index_path) { "#{node.url}/kurashi" }
  let(:rss_path) { "#{node.url}/kurashi/rss.xml" }
  let(:nothing_path) { "#{node.url}index.html" }

  it "#index" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit index_path
      expect(current_path).to eq index_path
    end
  end

  it "#rss" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit rss_path
      expect(current_path).to eq rss_path
    end
  end

  it "#nothing" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit nothing_path
      expect(current_path).to eq nothing_path
    end
  end
end
