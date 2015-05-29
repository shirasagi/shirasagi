require 'spec_helper'

describe "opendata_dataset_selects" do
  #before do
  #  ss_site
  #end
  let(:site) { ss_site }
  let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset_selects" }
  let(:dataset) { create(:opendata_dataset, node: node) }

  let(:index_path) { "/datasets/select"}

  it "#index" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit index_path
      expect(current_path).to eq index_path
    end
  end
end
