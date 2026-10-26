require 'spec_helper'
require Rails.root.join("lib/migrations/event/20261026000001_ical_link.rb")

RSpec.describe SS::Migration20261026000001, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :event_node_page, cur_site: site }
  let!(:item1) do
    ical_link = "https://www.example.jp/日本語"
    item = create(:event_page, cur_site: site, cur_node: node, ical_link: unique_url)
    item.set(ical_link: ical_link)
    item
  end
  let!(:item2) do
    ical_link = "/日本語"
    item = create(:event_page, cur_site: site, cur_node: node, ical_link: unique_url)
    item.set(ical_link: ical_link)
    item
  end
  let!(:item3) do
    ical_link = %(/x" onclick="alert(1)")
    item = create(:event_page, cur_site: site, cur_node: node, ical_link: unique_url)
    item.set(ical_link: ical_link)
    item
  end
  let!(:item4) do
    ical_link = "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    item = create(:event_page, cur_site: site, cur_node: node, ical_link: unique_url)
    item.set(ical_link: ical_link)
    item
  end
  let!(:item5) do
    ical_link = "javascript:alert(1)"
    item = create(:event_page, cur_site: site, cur_node: node, ical_link: unique_url)
    item.set(ical_link: ical_link)
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
    expect(item1.ical_link).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    expect(File.exist?(item1.path)).to be_falsey

    item2.reload
    expect(item2.ical_link).to eq "/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    expect(File.exist?(item2.path)).to be_falsey

    item3.reload
    expect(item3.ical_link).to eq "/x%22%20onclick=%22alert(1)%22"
    expect(File.exist?(item3.path)).to be_falsey

    item4.reload
    expect(item4.ical_link).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    expect(File.exist?(item4.path)).to be_falsey

    item5.reload
    expect(item5.ical_link).to be_blank
    expect(File.exist?(item5.path)).to be_falsey
  end
end
