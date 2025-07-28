require 'spec_helper'

describe Cms::Node::GenerateJob, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }

  let!(:root_page1) { create :cms_page, cur_site: cms_site, filename: "index.html", layout_id: layout.id }
  let!(:root_page2) { create :cms_page, cur_site: cms_site, filename: "page2.html", layout_id: layout.id }
  let!(:root_page3) { create :cms_page, cur_site: cms_site, filename: "page3.html", layout_id: layout.id }

  let!(:node1) { create :article_node_page, cur_site: cms_site, layout_id: layout.id }
  let!(:node1_page1) { create :article_page, cur_site: cms_site, cur_node: node1, layout_id: layout.id }
  let!(:node1_page2) { create :article_page, cur_site: cms_site, cur_node: node1, layout_id: layout.id }

  let!(:node2) { create :event_node_page, cur_site: cms_site, layout_id: layout.id }
  let!(:node1_page1) { create :event_page, cur_site: cms_site, cur_node: node2, layout_id: layout.id }
  let!(:node1_page2) { create :event_page, cur_site: cms_site, cur_node: node2, layout_id: layout.id }

  let!(:node3) { create :faq_node_page, cur_site: cms_site, layout_id: layout.id }
  let!(:node3_page1) { create :faq_page, cur_site: cms_site, cur_node: node3, layout_id: layout.id }
  let!(:node3_page2) { create :faq_page, cur_site: cms_site, cur_node: node3, layout_id: layout.id }

  let!(:node4) { create :article_node_page, cur_site: cms_site, cur_node: node1, layout_id: layout.id }
  let!(:node4_page1) { create :article_page, cur_site: cms_site, cur_node: node4, layout_id: layout.id }
  let!(:node4_page2) { create :article_page, cur_site: cms_site, cur_node: node4, layout_id: layout.id }

  let!(:node5) { create :event_node_page, cur_site: cms_site, cur_node: node2, layout_id: layout.id }
  let!(:node5_page1) { create :event_page, cur_site: cms_site, cur_node: node5, layout_id: layout.id }
  let!(:node5_page2) { create :event_page, cur_site: cms_site, cur_node: node5, layout_id: layout.id }

  let!(:node6) { create :faq_node_page, cur_site: cms_site, cur_node: node3, layout_id: layout.id }
  let!(:node6_page1) { create :faq_page, cur_site: cms_site, cur_node: node6, layout_id: layout.id }
  let!(:node6_page2) { create :faq_page, cur_site: cms_site, cur_node: node6, layout_id: layout.id }

  let(:segments) { %w(web01 web02 web03) }

  let(:web01_expected_pages) { Cms::Page.where(depth: 1).select { |item| (item.id % segments.size) == 0 } }
  let(:web02_expected_pages) { Cms::Page.where(depth: 1).select { |item| (item.id % segments.size) == 1 } }
  let(:web03_expected_pages) { Cms::Page.where(depth: 1).select { |item| (item.id % segments.size) == 2 } }

  let(:web01_expected_nodes) { Cms::Node.all.select { |item| (item.id % segments.size) == 0 } }
  let(:web02_expected_nodes) { Cms::Node.all.select { |item| (item.id % segments.size) == 1 } }
  let(:web03_expected_nodes) { Cms::Node.all.select { |item| (item.id % segments.size) == 2 } }

  let(:web01_expected_path) do
    web01_expected_pages.map(&:path) + web01_expected_nodes.map { |item| ::File.join(item.path, "index.html") }
  end
  let(:web02_expected_path) do
    web02_expected_pages.map(&:path) + web02_expected_nodes.map { |item| ::File.join(item.path, "index.html") }
  end
  let(:web03_expected_path) do
    web03_expected_pages.map(&:path) + web03_expected_nodes.map { |item| ::File.join(item.path, "index.html") }
  end

  before do
    @save_generate_segments = SS.config.cms.generate_segments
    SS.config.replace_value_at(:cms, :generate_segments, { "node" => { site.host => segments } })
  end

  after do
    SS.config.replace_value_at(:cms, :generate_segments, @save_generate_segments)
  end

  describe "#perform without segment" do
    before do
      Fs.rm_rf site.path
      described_class.bind(site_id: site.id).perform_now
    end

    it do
      expect(Job::Log.count).to eq 1
      web01_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }
      web02_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }
      web03_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }
    end
  end

  describe "#perform with web01" do
    before do
      Fs.rm_rf site.path
      described_class.bind(site_id: site.id).perform_now(segment: "web01")
    end

    it do
      expect(Job::Log.count).to eq 1
      web01_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }
      web02_expected_path.each { |path| expect(::File.exist?(path)).to be_falsey }
      web03_expected_path.each { |path| expect(::File.exist?(path)).to be_falsey }
    end
  end

  describe "#perform with web02" do
    before do
      Fs.rm_rf site.path
      described_class.bind(site_id: site.id).perform_now(segment: "web02")
    end

    it do
      expect(Job::Log.count).to eq 1
      web01_expected_path.each { |path| expect(::File.exist?(path)).to be_falsey }
      web02_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }
      web03_expected_path.each { |path| expect(::File.exist?(path)).to be_falsey }
    end
  end

  describe "#perform with web03" do
    before do
      Fs.rm_rf site.path
      described_class.bind(site_id: site.id).perform_now(segment: "web03")
    end

    it do
      expect(Job::Log.count).to eq 1
      web01_expected_path.each { |path| expect(::File.exist?(path)).to be_falsey }
      web02_expected_path.each { |path| expect(::File.exist?(path)).to be_falsey }
      web03_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }
    end
  end
end
