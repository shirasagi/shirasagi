require 'spec_helper'

describe Cms::NodeTree, dbscope: :example do
  let!(:site) { cms_site }

  let!(:c1) { create :category_node_node, site: site, filename: "A" }
  let!(:c1_1) { create :category_node_node, site: site, filename: "A/B" }
  let!(:c1_1_1) { create :category_node_page, site: site, filename: "A/B/C" }
  let!(:c1_1_2) { create :category_node_page, site: site, filename: "A/B/D" }
  let!(:c1_2) { create :category_node_node, site: site, filename: "A/E" }
  let!(:c1_2_1) { create :category_node_page, site: site, filename: "A/E/F" }
  let!(:c1_2_2) { create :category_node_page, site: site, filename: "A/E/G" }
  let!(:c2) { create :category_node_page, site: site, filename: "H" }

  let!(:n1) { create :cms_node_node, site: site, filename: "node" }
  let!(:n1_1) { create :category_node_node, site: site, filename: "node/I" }
  let!(:n1_1_1) { create :category_node_page, site: site, filename: "node/I/J" }
  let!(:n1_1_2) { create :category_node_page, site: site, filename: "node/I/K" }

  let(:nodes) { Category::Node::Base.site(site).tree_sort.to_a }
  let(:tree) { described_class.build(nodes) }

  context "normal case" do
    it do
      expect(tree.roots.size).to eq 3

      item = tree.roots[0]
      expect(item.id).to eq c1.id
      expect(item.name).to eq c1.name
      expect(item.depth).to eq 1
      expect(item.basename).to eq c1.basename
      expect(item.filename).to eq c1.filename
      expect(item.node.name).to eq c1.name
      expect(item.parent).to eq nil
      expect(item.children.map(&:id)).to match_array [c1_1, c1_2].map(&:id)
      expect(item.descendants.map(&:id)).to match_array [c1_1, c1_2, c1_1_1, c1_1_2, c1_2_1, c1_2_2].map(&:id)

      item = tree.roots[1]
      expect(item.id).to eq c2.id
      expect(item.name).to eq c2.name
      expect(item.depth).to eq 1
      expect(item.basename).to eq c2.basename
      expect(item.filename).to eq c2.filename
      expect(item.node.name).to eq c2.name
      expect(item.parent).to eq nil
      expect(item.children.map(&:id)).to match_array []
      expect(item.descendants.map(&:id)).to match_array []

      item = tree.roots[2]
      expect(item.id).to eq n1_1.id
      expect(item.name).to eq n1_1.name
      expect(item.depth).to eq 2
      expect(item.basename).to eq n1_1.basename
      expect(item.filename).to eq n1_1.filename
      expect(item.node.name).to eq n1_1.name
      expect(item.parent).to eq nil
      expect(item.children.map(&:id)).to match_array [n1_1_1, n1_1_2].map(&:id)
      expect(item.descendants.map(&:id)).to match_array [n1_1_1, n1_1_2].map(&:id)

      item = tree.roots[0].children.find { |c| c.id == c1_1.id }
      expect(item.id).to eq c1_1.id
      expect(item.name).to eq c1_1.name
      expect(item.depth).to eq 2
      expect(item.basename).to eq c1_1.basename
      expect(item.filename).to eq c1_1.filename
      expect(item.node.name).to eq c1_1.name
      expect(item.parent.id).to eq c1.id
      expect(item.children.map(&:id)).to match_array [c1_1_1, c1_1_2].map(&:id)
      expect(item.descendants.map(&:id)).to match_array [c1_1_1, c1_1_2].map(&:id)

      item = tree.roots[0].children.find { |c| c.id == c1_2.id }
      expect(item.id).to eq c1_2.id
      expect(item.name).to eq c1_2.name
      expect(item.depth).to eq 2
      expect(item.basename).to eq c1_2.basename
      expect(item.filename).to eq c1_2.filename
      expect(item.node.name).to eq c1_2.name
      expect(item.parent.id).to eq c1.id
      expect(item.children.map(&:id)).to match_array [c1_2_1, c1_2_2].map(&:id)
      expect(item.descendants.map(&:id)).to match_array [c1_2_1, c1_2_2].map(&:id)

      item = tree.roots[0].descendants.find { |c| c.id == c1_1_1.id }
      expect(item.id).to eq c1_1_1.id
      expect(item.name).to eq c1_1_1.name
      expect(item.depth).to eq 3
      expect(item.basename).to eq c1_1_1.basename
      expect(item.filename).to eq c1_1_1.filename
      expect(item.node.name).to eq c1_1_1.name
      expect(item.parent.id).to eq c1_1.id
      expect(item.children.map(&:id)).to match_array []
      expect(item.descendants.map(&:id)).to match_array []

      item = tree.roots[2].children.find { |c| c.id == n1_1_1.id }
      expect(item.id).to eq n1_1_1.id
      expect(item.name).to eq n1_1_1.name
      expect(item.depth).to eq 3
      expect(item.basename).to eq n1_1_1.basename
      expect(item.filename).to eq n1_1_1.filename
      expect(item.node.name).to eq n1_1_1.name
      expect(item.parent.id).to eq n1_1.id
      expect(item.children.map(&:id)).to match_array []
      expect(item.descendants.map(&:id)).to match_array []
    end
  end
end
