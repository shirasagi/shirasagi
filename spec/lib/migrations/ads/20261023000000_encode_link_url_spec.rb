require 'spec_helper'
require Rails.root.join("lib/migrations/ads/20261023000000_encode_link_url.rb")

RSpec.describe SS::Migration20261023000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :ads_node_banner, cur_site: site }
  let!(:item1) { create(:ads_banner, cur_site: site, cur_node: node, link_url: "https://www.example.jp/日本語") }
  let!(:item2) { create(:ads_banner, cur_site: site, cur_node: node, link_url: "/日本語") }
  let!(:item3) { create(:ads_banner, cur_site: site, cur_node: node, link_url: %(/x" onclick="alert(1)")) }
  let!(:item4) { create(:ads_banner, cur_site: site, cur_node: node, link_url: "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E") }

  before do
    described_class.new.change
  end

  it do
    item1.reload
    expect(item1.link_url).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"

    item2.reload
    expect(item2.link_url).to eq "/%E6%97%A5%E6%9C%AC%E8%AA%9E"

    item3.reload
    expect(item3.link_url).to eq "/x%22%20onclick=%22alert(1)%22"

    item4.reload
    expect(item4.link_url).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
  end
end
