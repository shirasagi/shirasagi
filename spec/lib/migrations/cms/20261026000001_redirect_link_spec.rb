require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20261026000001_redirect_link.rb")

RSpec.describe SS::Migration20261026000001, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :rss_node_page, cur_site: site }
  let!(:page1) do
    item = create(:cms_page, cur_site: site, cur_node: node)
    redirect_link = "https://www.example.jp/日本語"
    item.set(redirect_link: redirect_link)
    item
  end
  let!(:page2) do
    item = create(:article_page, cur_site: site, cur_node: node)
    redirect_link = "/日本語"
    item.set(redirect_link: redirect_link)
    item
  end
  let!(:page3) do
    item = create(:event_page, cur_site: site, cur_node: node)
    redirect_link = %(/x" onclick="alert(1)")
    item.set(redirect_link: redirect_link)
    item
  end
  let!(:page4) do
    item = create(:facility_notice, cur_site: site, cur_node: node)
    redirect_link = "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    item.set(redirect_link: redirect_link)
    item
  end
  let!(:page5) do
    item = create(:cms_page, cur_site: site, cur_node: node)
    redirect_link = "javascript:alert(1)"
    item.set(redirect_link: redirect_link)
    item
  end

  let!(:node1) do
    item = create(:cms_node_page, cur_site: site, cur_node: node)
    redirect_link = "https://www.example.jp/日本語"
    item.set(redirect_link: redirect_link)
    item
  end
  let!(:node2) do
    item = create(:cms_node_node, cur_site: site, cur_node: node)
    redirect_link = "/日本語"
    item.set(redirect_link: redirect_link)
    item
  end
  let!(:node3) do
    item = create(:article_node_page, cur_site: site, cur_node: node)
    redirect_link = %(/x" onclick="alert(1)")
    item.set(redirect_link: redirect_link)
    item
  end
  let!(:node4) do
    item = create(:category_node_node, cur_site: site, cur_node: node)
    redirect_link = "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    item.set(redirect_link: redirect_link)
    item
  end
  let!(:node5) do
    item = create(:category_node_page, cur_site: site, cur_node: node)
    redirect_link = "javascript:alert(1)"
    item.set(redirect_link: redirect_link)
    item
  end

  before do
    described_class.new.change
  end

  it do
    page1.reload
    expect(page1.redirect_link).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    expect(File.exist?(page1.path)).to be_falsey

    page2.reload
    expect(page2.redirect_link).to eq "/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    expect(File.exist?(page2.path)).to be_falsey

    page3.reload
    expect(page3.redirect_link).to eq "/x%22%20onclick=%22alert(1)%22"
    expect(File.exist?(page3.path)).to be_falsey

    page4.reload
    expect(page4.redirect_link).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    expect(File.exist?(page4.path)).to be_falsey

    page5.reload
    expect(page5.redirect_link).to be_blank
    expect(File.exist?(page5.path)).to be_falsey

    node1.reload
    expect(node1.redirect_link).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    expect(File.exist?(node1.path)).to be_falsey

    node2.reload
    expect(node2.redirect_link).to eq "/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    expect(File.exist?(node2.path)).to be_falsey

    node3.reload
    expect(node3.redirect_link).to eq "/x%22%20onclick=%22alert(1)%22"
    expect(File.exist?(node3.path)).to be_falsey

    node4.reload
    expect(node4.redirect_link).to eq "https://www.example.jp/%E6%97%A5%E6%9C%AC%E8%AA%9E"
    expect(File.exist?(node4.path)).to be_falsey

    node5.reload
    expect(node5.redirect_link).to be_blank
    expect(File.exist?(node5.path)).to be_falsey
  end
end
