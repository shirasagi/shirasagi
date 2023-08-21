require 'spec_helper'

describe "opendata_agents_nodes_url_resource", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:original_url) { unique_url }

  before do
    @net_connect_allowed = WebMock.net_connect_allowed?
    WebMock.disable_net_connect!
    WebMock.reset!

    headers = { "ETag" => rand(0x100000000).to_s(36), "Last-Modified" => Time.zone.now.httpdate }
    stub_request(:get, original_url).
      to_return(status: 200, body: ::File.binread("#{Rails.root}/spec/fixtures/opendata/shift_jis.csv"), headers: headers)
  end

  after do
    WebMock.reset!
    WebMock.allow_net_connect! if @net_connect_allowed
  end

  describe "#download" do
    let!(:node_search) { create :opendata_node_search_dataset }

    let!(:node) { create :opendata_node_dataset, name: "opendata_agents_nodes_url_resource" }
    let!(:dataset) { create :opendata_dataset, cur_node: node, filename: "1.html" }

    let!(:license) { create(:opendata_license, cur_site: site) }
    let!(:url_resource) do
      url_resource = dataset.url_resources.new(
        name: "test",
        text: "text",
        license_id: license.id,
        original_url: original_url,
        crawl_update: "none")
      url_resource.save!
      url_resource
    end
    let(:download_path) { url_resource.download_url }

    it "#download" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit download_path
        expect(current_path).to eq download_path
      end
    end
  end
end
