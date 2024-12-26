require 'spec_helper'

describe Cms::Page::GenerateJob, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }

  let!(:node) { create :article_node_page, cur_site: cms_site, layout_id: layout.id }
  let!(:page1) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page2) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page3) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page4) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page5) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page6) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page7) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page8) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page9) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }

  let(:segments) { %w(web01 web02 web03) }

  let(:web01_expected_pages) { Cms::Page.all.select { |item| (item.id % segments.size) == 0 } }
  let(:web02_expected_pages) { Cms::Page.all.select { |item| (item.id % segments.size) == 1 } }
  let(:web03_expected_pages) { Cms::Page.all.select { |item| (item.id % segments.size) == 2 } }

  let(:web01_expected_path) { web01_expected_pages.map(&:path) }
  let(:web02_expected_path) { web02_expected_pages.map(&:path) }
  let(:web03_expected_path) { web03_expected_pages.map(&:path) }

  before do
    @save_generate_segments = SS.config.cms.generate_segments
    SS.config.replace_value_at(:cms, :generate_segments, { "page" => { site.host => segments } })
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
      web01_expected_path.each { |path| expect(File.exist?(path)).to be_truthy }
      web02_expected_path.each { |path| expect(File.exist?(path)).to be_truthy }
      web03_expected_path.each { |path| expect(File.exist?(path)).to be_truthy }
    end
  end

  describe "#perform with web01" do
    before do
      Fs.rm_rf site.path
      described_class.bind(site_id: site.id).perform_now(segment: "web01")
    end

    it do
      expect(Job::Log.count).to eq 1
      web01_expected_path.each { |path| expect(File.exist?(path)).to be_truthy }
      web02_expected_path.each { |path| expect(File.exist?(path)).to be_falsey }
      web03_expected_path.each { |path| expect(File.exist?(path)).to be_falsey }
    end
  end

  describe "#perform with web02" do
    before do
      Fs.rm_rf site.path
      described_class.bind(site_id: site.id).perform_now(segment: "web02")
    end

    it do
      expect(Job::Log.count).to eq 1
      web01_expected_path.each { |path| expect(File.exist?(path)).to be_falsey }
      web02_expected_path.each { |path| expect(File.exist?(path)).to be_truthy }
      web03_expected_path.each { |path| expect(File.exist?(path)).to be_falsey }
    end
  end

  describe "#perform with web03" do
    before do
      Fs.rm_rf site.path
      described_class.bind(site_id: site.id).perform_now(segment: "web03")
    end

    it do
      expect(Job::Log.count).to eq 1
      web01_expected_path.each { |path| expect(File.exist?(path)).to be_falsey }
      web02_expected_path.each { |path| expect(File.exist?(path)).to be_falsey }
      web03_expected_path.each { |path| expect(File.exist?(path)).to be_truthy }
    end
  end
end
