require 'spec_helper'

describe Lsorg::Node::Node, dbscope: :example do
  let(:site) { cms_site }

  let!(:g1) { create :cms_group, name: "A" }
  let!(:g1_1) { create :cms_group, name: "A/B" }
  let!(:g1_1_1) { create :cms_group, name: "A/B/C" }
  let!(:g1_1_2) { create :cms_group, name: "A/B/D" }
  let!(:g1_2) { create :cms_group, name: "A/E" }
  let!(:g1_2_1) { create :cms_group, name: "A/E/F" }
  let!(:g1_2_2) { create :cms_group, name: "A/E/G/H" }
  let!(:g1_3) { create :cms_group, name: "A/I/J" }

  let!(:g2) { create :cms_group, name: "K" }
  let!(:g2_1) { create :cms_group, name: "K/L" }
  let!(:g2_2) { create :cms_group, name: "K/M" }

  context "g1" do
    let!(:node) { create :lsorg_node_node, cur_site: site, root_group_ids: [g1].map(&:id) }

    it do
      expect(node.effective_root_groups.map(&:id)).to match_array [g1].map(&:id)
    end
  end

  context "g1, g2" do
    let!(:node) { create :lsorg_node_node, cur_site: site, root_group_ids: [g1, g2].map(&:id) }

    it do
      expect(node.effective_root_groups.map(&:id)).to match_array [g1, g2].map(&:id)
    end
  end

  context "g1, g2, g1_1" do
    let!(:node) { create :lsorg_node_node, cur_site: site, root_group_ids: [g1, g2, g1_1].map(&:id) }

    it do
      expect(node.effective_root_groups.map(&:id)).to match_array [g1, g2].map(&:id)
    end
  end

  context "g1_1, g1_2" do
    let!(:node) { create :lsorg_node_node, cur_site: site, root_group_ids: [g1_1, g1_2].map(&:id) }

    it do
      expect(node.effective_root_groups.map(&:id)).to match_array [g1_1, g1_2].map(&:id)
    end
  end

  context "g1_1, g1_2, g1_1_1" do
    let!(:node) { create :lsorg_node_node, cur_site: site, root_group_ids: [g1_1, g1_2, g1_1_1].map(&:id) }

    it do
      expect(node.effective_root_groups.map(&:id)).to match_array [g1_1, g1_2].map(&:id)
    end
  end

  context "g1_1, g1_2, g1_1_1, g2" do
    let!(:node) { create :lsorg_node_node, cur_site: site, root_group_ids: [g1_1, g1_2, g1_1_1, g2].map(&:id) }

    it do
      expect(node.effective_root_groups.map(&:id)).to match_array [g1_1, g1_2, g2].map(&:id)
    end
  end

  context "all groups" do
    let!(:node) do
      create :lsorg_node_node, cur_site: site, root_group_ids: [
        g1, g1_1, g1_2, g1_1_1, g1_1_2, g1_2, g1_2_1, g1_2_2, g1_3,
        g2, g2_1, g2_2].map(&:id)
    end

    it do
      expect(node.effective_root_groups.map(&:id)).to match_array [g1, g2].map(&:id)
    end
  end
end
