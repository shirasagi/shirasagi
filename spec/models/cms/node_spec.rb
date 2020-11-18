require 'spec_helper'

describe Cms::Node, type: :model, dbscope: :example do
  let(:item) { create :cms_node }
  it_behaves_like "cms_node#spec"
end

describe Cms::Node::Base do
end

describe Cms::Node::Node do
  let(:item) { create :cms_node_node }
  it_behaves_like "cms_node#spec"

  describe "validation" do
    it "basename" do
      item = build(:cms_node_node_basename_invalid)
      expect(item.invalid?).to be_truthy
    end
  end
end

describe Cms::Node::Page, dbscope: :example do
  let(:item) { create :cms_node_page }
  it_behaves_like "cms_node#spec"

  describe ".and_public" do
    let(:site) { cms_site }
    let(:current) { Time.zone.now.beginning_of_minute }
    let!(:node1) { create :cms_node_page, site: site, released: current, state: "public" }
    let!(:node2) { create :cms_node_page, site: site, released: current, state: "closed" }
    let!(:node3) { create :cms_node_page, site: site, released: current + 1.day, state: "public" }
    let!(:node4) { create :cms_node_page, site: site, released: current + 1.day, state: "closed" }

    it do
      # without specific date to and_public
      expect(described_class.and_public.count).to eq 2
      expect(described_class.and_public.pluck(:id)).to include(node1.id, node3.id)
      expect(Cms::Node.and_public.count).to eq 2
      expect(Cms::Node.and_public.pluck(:id)).to include(node1.id, node3.id)

      # at current
      expect(described_class.and_public(current).count).to eq 1
      expect(described_class.and_public(current).pluck(:id)).to include(node1.id)
      expect(Cms::Node.and_public(current).count).to eq 1
      expect(Cms::Node.and_public(current).pluck(:id)).to include(node1.id)

      # at current + 1.day
      expect(described_class.and_public(current + 1.day).count).to eq 2
      expect(described_class.and_public(current + 1.day).pluck(:id)).to include(node1.id, node3.id)
      expect(Cms::Node.and_public(current + 1.day).count).to eq 2
      expect(Cms::Node.and_public(current + 1.day).pluck(:id)).to include(node1.id, node3.id)
    end
  end

  describe "#public?" do
    let(:site) { cms_site }
    let(:current) { Time.zone.now.beginning_of_minute }
    let!(:node1) { create :cms_node_page, site: site, released: current, state: "public" }
    let!(:node2) { create :cms_node_page, site: site, released: current, state: "closed" }
    let!(:node3) { create :cms_node_page, site: site, released: current + 1.day, state: "public" }
    let!(:node4) { create :cms_node_page, site: site, released: current + 1.day, state: "closed" }

    it do
      expect(node1.public?).to be_truthy
      expect(node2.public?).to be_falsey
      expect(node3.public?).to be_truthy
      expect(node4.public?).to be_falsey

      # at current
      Timecop.freeze(current) do
        node1.reload
        node2.reload
        node3.reload
        node4.reload

        expect(node1.public?).to be_truthy
        expect(node2.public?).to be_falsey
        expect(node3.public?).to be_truthy
        expect(node4.public?).to be_falsey
      end

      # at current + 1.day
      Timecop.freeze(current + 1.day) do
        node1.reload
        node2.reload
        node3.reload
        node4.reload

        expect(node1.public?).to be_truthy
        expect(node2.public?).to be_falsey
        expect(node3.public?).to be_truthy
        expect(node4.public?).to be_falsey
      end
    end
  end
end
