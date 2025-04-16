require 'spec_helper'

describe Ads::Banner do
  subject(:model) { Ads::Banner }
  subject(:factory) { :ads_banner }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    let(:node) { create :article_node_page }
    let(:item) { create :ads_banner, cur_node: node }
    let(:show_path) { Rails.application.routes.url_helpers.ads_banner_path(site: item.site, cid: node, id: item.id) }

    it { expect(item.dirname).to eq node.filename }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.parent).to eq node }
    it { expect(item.private_show_path).to eq show_path }
    it { expect(item.count_url).not_to eq nil }
  end

  describe "validation" do
    let(:site) { cms_site }
    let(:node) { create :ads_node_banner, cur_site: site }
    let(:file) { create :ss_file, site_id: site.id }

    let(:valid_url1) { "http://example.jp/" }
    let(:valid_url2) { "https://example.jp/" }
    let(:valid_url3) { "/docs/page1.html" }
    let(:valid_url4) { "/docs/" }
    let(:valid_url5) { "//www.example.jp/docs/3481.html" }

    let(:invalid_url1) { "http://example.jp /" }
    let(:invalid_url2) { "https://example.jp /" }
    let(:invalid_url3) { "javascript:alert('test')" }
    let(:invalid_url4) { "javascript:void(0)" }
    let(:invalid_url5) { "#" }

    def build_banner(url)
      build(
        :ads_banner, cur_site: site, cur_node: node,
        file_id: file.id,
        link_url: url
      )
    end

    it "valid_url1" do
      item = build_banner(valid_url1)
      expect(item.valid?).to be_truthy
    end

    it "valid_url2" do
      item = build_banner(valid_url2)
      expect(item.valid?).to be_truthy
    end

    it "valid_url3" do
      item = build_banner(valid_url3)
      expect(item.valid?).to be_truthy
    end

    it "valid_url4" do
      item = build_banner(valid_url4)
      expect(item.valid?).to be_truthy
    end

    it "valid_url5" do
      item = build_banner(valid_url5)
      expect(item.valid?).to be_truthy
    end

    it "invalid_url1" do
      item = build_banner(invalid_url1)
      expect(item.valid?).to be_falsey
      expect(item.errors[:link_url]).to be_present
    end

    it "invalid_url2" do
      item = build_banner(invalid_url2)
      expect(item.valid?).to be_falsey
      expect(item.errors[:link_url]).to be_present
    end

    it "invalid_url3" do
      item = build_banner(invalid_url3)
      expect(item.valid?).to be_falsey
      expect(item.errors[:link_url]).to be_present
    end

    it "invalid_url4" do
      item = build_banner(invalid_url4)
      expect(item.valid?).to be_falsey
      expect(item.errors[:link_url]).to be_present
    end

    it "invalid_url5" do
      item = build_banner(invalid_url5)
      expect(item.valid?).to be_falsey
      expect(item.errors[:link_url]).to be_present
    end

    context "when file is not present" do
      it "valid_url1" do
        item = build(:ads_banner, cur_site: site, cur_node: node, link_url: valid_url1)
        expect(item.valid?).to be_truthy
      end

      it "valid_url2" do
        item = build(:ads_banner, cur_site: site, cur_node: node, link_url: valid_url2)
        expect(item.valid?).to be_truthy
      end

      it "valid_url3" do
        item = build(:ads_banner, cur_site: site, cur_node: node, link_url: valid_url3)
        expect(item.valid?).to be_truthy
      end

      it "valid_url4" do
        item = build(:ads_banner, cur_site: site, cur_node: node, link_url: valid_url4)
        expect(item.valid?).to be_truthy
      end
    end
  end
end
