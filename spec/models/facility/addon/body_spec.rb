require 'spec_helper'

describe Facility::Addon::Body do
  let(:site) { cms_site }
  let(:node) { create :facility_node_page, cur_site: site }
  let(:item) { create :facility_node_page, cur_site: site, cur_node: node }

  describe "validation" do
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

    def build_item(url)
      build(
        :facility_node_page, cur_site: site, cur_node: node,
        related_url: url
      )
    end

    it "valid_url1" do
      item = build_item(valid_url1)
      expect(item.valid?).to be_truthy
    end

    it "valid_url2" do
      item = build_item(valid_url2)
      expect(item.valid?).to be_truthy
    end

    it "valid_url3" do
      item = build_item(valid_url3)
      expect(item.valid?).to be_truthy
    end

    it "valid_url4" do
      item = build_item(valid_url4)
      expect(item.valid?).to be_truthy
    end

    it "valid_url5" do
      item = build_item(valid_url5)
      expect(item.valid?).to be_truthy
    end

    it "invalid_url1" do
      item = build_item(invalid_url1)
      expect(item.valid?).to be_falsey
      expect(item.errors[:related_url]).to be_present
    end

    it "invalid_url2" do
      item = build_item(invalid_url2)
      expect(item.valid?).to be_falsey
      expect(item.errors[:related_url]).to be_present
    end

    it "invalid_url3" do
      item = build_item(invalid_url3)
      expect(item.valid?).to be_falsey
      expect(item.errors[:related_url]).to be_present
    end

    it "invalid_url4" do
      item = build_item(invalid_url4)
      expect(item.valid?).to be_falsey
      expect(item.errors[:related_url]).to be_present
    end

    it "invalid_url5" do
      item = build_item(invalid_url5)
      expect(item.valid?).to be_falsey
      expect(item.errors[:related_url]).to be_present
    end
  end
end
