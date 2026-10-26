require 'spec_helper'
require Rails.root.join("lib/migrations/ads/20261023000000_encode_link_url.rb")

RSpec.describe SS::Migration20261023000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :ads_node_banner, cur_site: site }
  let!(:item1) do
    link_url = "https://www.example.jp/日本語"
    item = create(:ads_banner, cur_site: site, cur_node: node, link_url: unique_url)
    item.set(link_url: link_url)
    item
  end
  let!(:item2) do
    link_url = "/日本語"
    item = create(:ads_banner, cur_site: site, cur_node: node, link_url: unique_url)
    item.set(link_url: link_url)
    item
  end
  let!(:item3) do
    link_url = %(/x" onclick="alert(1)")
    item = create(:ads_banner, cur_site: site, cur_node: node, link_url: unique_url)
    item.set(link_url: link_url)
    item
  end
  let!(:item4) do
    link_url = "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    item = create(:ads_banner, cur_site: site, cur_node: node, link_url: unique_url)
    item.set(link_url: link_url)
    item
  end
  let!(:item5) do
    link_url = "javascript:alert(1)"
    item = create(:ads_banner, cur_site: site, cur_node: node, link_url: unique_url)
    item.set(link_url: link_url)
    item
  end

  before do
    expect(File.exist?(item1.path)).to be_truthy
    expect(File.exist?(item2.path)).to be_truthy
    expect(File.exist?(item3.path)).to be_truthy
    expect(File.exist?(item4.path)).to be_truthy
    expect(File.exist?(item5.path)).to be_truthy

    described_class.new.change
  end

  it do
    item1.reload
    expect(item1.link_url).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    expect(File.exist?(item1.path)).to be_falsey

    item2.reload
    expect(item2.link_url).to eq "/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    expect(File.exist?(item2.path)).to be_falsey

    item3.reload
    expect(item3.link_url).to eq "/x%22%20onclick=%22alert(1)%22"
    expect(File.exist?(item3.path)).to be_falsey

    item4.reload
    expect(item4.link_url).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    expect(File.exist?(item4.path)).to be_truthy # マイグレーション前後で link_url に変化がないので書き出しファイルが存在する

    item5.reload
    expect(item5.link_url).to be_blank
    expect(File.exist?(item5.path)).to be_falsey
  end
end
