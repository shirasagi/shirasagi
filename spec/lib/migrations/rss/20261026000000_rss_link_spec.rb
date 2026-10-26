require 'spec_helper'
require Rails.root.join("lib/migrations/rss/20261026000000_rss_link.rb")

RSpec.describe SS::Migration20261026000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :rss_node_page, cur_site: site }
  let!(:item1_1) do
    rss_link = "https://www.example.jp/日本語"
    item = create(:rss_page, cur_site: site, cur_node: node, rss_link: unique_url)
    item.set(rss_link: rss_link)
    item
  end
  let!(:item1_2) do
    rss_link = "/日本語"
    item = create(:rss_page, cur_site: site, cur_node: node, rss_link: unique_url)
    item.set(rss_link: rss_link)
    item
  end
  let!(:item1_3) do
    rss_link = %(/x" onclick="alert(1)")
    item = create(:rss_page, cur_site: site, cur_node: node, rss_link: unique_url)
    item.set(rss_link: rss_link)
    item
  end
  let!(:item1_4) do
    rss_link = "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    item = create(:rss_page, cur_site: site, cur_node: node, rss_link: unique_url)
    item.set(rss_link: rss_link)
    item
  end
  let!(:item1_5) do
    rss_link = "javascript:alert(1)"
    item = create(:rss_page, cur_site: site, cur_node: node, rss_link: unique_url)
    item.set(rss_link: rss_link)
    item
  end

  let!(:item2_1) do
    rss_link = "https://www.example.jp/日本語"
    item = create(:rss_weather_xml_page, cur_site: site, cur_node: node, rss_link: unique_url)
    item.set(rss_link: rss_link)
    item
  end
  let!(:item2_2) do
    rss_link = "/日本語"
    item = create(:rss_weather_xml_page, cur_site: site, cur_node: node, rss_link: unique_url)
    item.set(rss_link: rss_link)
    item
  end
  let!(:item2_3) do
    rss_link = %(/x" onclick="alert(1)")
    item = create(:rss_weather_xml_page, cur_site: site, cur_node: node, rss_link: unique_url)
    item.set(rss_link: rss_link)
    item
  end
  let!(:item2_4) do
    rss_link = "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    item = create(:rss_weather_xml_page, cur_site: site, cur_node: node, rss_link: unique_url)
    item.set(rss_link: rss_link)
    item
  end
  let!(:item2_5) do
    rss_link = "javascript:alert(1)"
    item = create(:rss_weather_xml_page, cur_site: site, cur_node: node, rss_link: unique_url)
    item.set(rss_link: rss_link)
    item
  end

  before do
    described_class.new.change
  end

  it do
    item1_1.reload
    expect(item1_1.rss_link).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"

    item1_2.reload
    expect(item1_2.rss_link).to eq "/%E6%97%A5%E6%9C%AC%E8%AA%9E"

    item1_3.reload
    expect(item1_3.rss_link).to eq "/x%22%20onclick=%22alert(1)%22"

    item1_4.reload
    expect(item1_4.rss_link).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"

    item1_5.reload
    expect(item1_5.rss_link).to be_blank

    item2_1.reload
    expect(item2_1.rss_link).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"

    item2_2.reload
    expect(item2_2.rss_link).to eq "/%E6%97%A5%E6%9C%AC%E8%AA%9E"

    item2_3.reload
    expect(item2_3.rss_link).to eq "/x%22%20onclick=%22alert(1)%22"

    item2_4.reload
    expect(item2_4.rss_link).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"

    item2_5.reload
    expect(item2_5.rss_link).to be_blank
  end
end
