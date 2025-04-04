require 'spec_helper'

describe KeyVisual::Image, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :key_visual_node_image, cur_site: site }
  subject { create :key_visual_image, cur_site: site, cur_node: node }
  let(:show_path) do
    Rails.application.routes.url_helpers.key_visual_image_path(site: subject.site, cid: subject.parent, id: subject)
  end

  describe "#attributes" do
    it { expect(subject.dirname).to eq node.filename }
    it { expect(subject.basename).not_to eq nil }
    it { expect(subject.path).not_to eq nil }
    it { expect(subject.url).not_to eq nil }
    it { expect(subject.full_url).not_to eq nil }
    it { expect(subject.parent).to eq node }
    it { expect(subject.private_show_path).to eq show_path }
  end

  describe "validation" do
    let(:valid_url1) { "http://example.jp/" }
    let(:valid_url2) { "https://example.jp/" }
    let(:valid_url3) { "/docs/page1.html" }
    let(:valid_url4) { "/docs/" }

    let(:invalid_url1) { "http://example.jp /" }
    let(:invalid_url2) { "https://example.jp /" }
    let(:invalid_url3) { "javascript:alert('test')" }
    let(:invalid_url4) { "javascript:void(0)" }
    let(:invalid_url5) { "#" }

    def build_item(url)
      build(
        :key_visual_image, cur_site: site, cur_node: node,
        link_url: url
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

    it "invalid_url1" do
      item = build_item(invalid_url1)
      expect(item.valid?).to be_falsey
      expect(item.errors[:link_url]).to be_present
    end

    it "invalid_url2" do
      item = build_item(invalid_url2)
      expect(item.valid?).to be_falsey
      expect(item.errors[:link_url]).to be_present
    end

    it "invalid_url3" do
      item = build_item(invalid_url3)
      expect(item.valid?).to be_falsey
      expect(item.errors[:link_url]).to be_present
    end

    it "invalid_url4" do
      item = build_item(invalid_url4)
      expect(item.valid?).to be_falsey
      expect(item.errors[:link_url]).to be_present
    end

    it "invalid_url5" do
      item = build_item(invalid_url5)
      expect(item.valid?).to be_falsey
      expect(item.errors[:link_url]).to be_present
    end
  end
end
