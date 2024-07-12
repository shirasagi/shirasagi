require 'spec_helper'

describe Lsorg::GroupTree, dbscope: :example do
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

  context "normal case" do
    it do
      root = described_class.build(g1)

      expect(root.name).to eq "A"
      expect(root.full_name).to eq "A"
      expect(root.group.name).to eq "A"
      expect(root.depth).to eq 0
      expect(root.basename).to eq g1.basename
      expect(root.filename).to eq g1.basename
      expect(root.root.group.id).to eq g1.id
      expect(root.parent).to eq nil
      expect(root.children.map { |c| c.group.id }).to match_array [g1_1.id, g1_2.id, g1_3.id]
      expect(root.descendants.map { |c| c.group.id }).to match_array [g1_1.id, g1_1_1.id, g1_1_2.id, g1_2.id, g1_2_1.id, g1_2_2.id, g1_3.id]

      c1_1 = root.children.find { |c| c.group.id == g1_1.id }
      c1_2 = root.children.find { |c| c.group.id == g1_2.id }

      expect(c1_1.name).to eq "B"
      expect(c1_1.full_name).to eq "A/B"
      expect(c1_1.group.name).to eq "A/B"
      expect(c1_1.depth).to eq 1
      expect(c1_1.basename).to eq g1_1.basename
      expect(c1_1.filename).to eq "#{g1.basename}/#{g1_1.basename}"
      expect(c1_1.root.group.id).to eq g1.id
      expect(c1_1.parent.group.id).to eq g1.id
      expect(c1_1.children.map { |c| c.group.id }).to match_array [g1_1_1.id, g1_1_2.id]
      expect(c1_1.descendants.map { |c| c.group.id }).to match_array [g1_1_1.id, g1_1_2.id]

      expect(c1_2.name).to eq "E"
      expect(c1_2.full_name).to eq "A/E"
      expect(c1_2.group.name).to eq "A/E"
      expect(c1_2.depth).to eq 1
      expect(c1_2.basename).to eq g1_2.basename
      expect(c1_2.filename).to eq "#{g1.basename}/#{g1_2.basename}"
      expect(c1_2.root.group.id).to eq g1.id
      expect(c1_2.parent.group.id).to eq g1.id
      expect(c1_2.children.map { |c| c.group.id }).to match_array [g1_2_1.id, g1_2_2.id]
      expect(c1_2.descendants.map { |c| c.group.id }).to match_array [g1_2_1.id, g1_2_2.id]

      c1_1_1 = c1_1.children.find { |c| c.group.id == g1_1_1.id }
      c1_1_2 = c1_1.children.find { |c| c.group.id == g1_1_2.id }
      c1_2_1 = c1_2.children.find { |c| c.group.id == g1_2_1.id }
      c1_2_2 = c1_2.children.find { |c| c.group.id == g1_2_2.id }

      expect(c1_1_1.name).to eq "C"
      expect(c1_1_1.full_name).to eq "A/B/C"
      expect(c1_1_1.group.name).to eq "A/B/C"
      expect(c1_1_1.depth).to eq 2
      expect(c1_1_1.basename).to eq g1_1_1.basename
      expect(c1_1_1.filename).to eq "#{g1.basename}/#{g1_1.basename}/#{g1_1_1.basename}"
      expect(c1_1_1.root.group.id).to eq g1.id
      expect(c1_1_1.parent.group.id).to eq g1_1.id
      expect(c1_1_1.children.map { |c| c.group.id }).to match_array []
      expect(c1_1_1.descendants.map { |c| c.group.id }).to match_array []

      expect(c1_1_2.name).to eq "D"
      expect(c1_1_2.full_name).to eq "A/B/D"
      expect(c1_1_2.group.name).to eq "A/B/D"
      expect(c1_1_2.depth).to eq 2
      expect(c1_1_2.basename).to eq g1_1_2.basename
      expect(c1_1_2.filename).to eq "#{g1.basename}/#{g1_1.basename}/#{g1_1_2.basename}"
      expect(c1_1_2.root.group.id).to eq g1.id
      expect(c1_1_2.parent.group.id).to eq g1_1.id
      expect(c1_1_2.children.map { |c| c.group.id }).to match_array []
      expect(c1_1_2.descendants.map { |c| c.group.id }).to match_array []

      expect(c1_2_1.name).to eq "F"
      expect(c1_2_1.full_name).to eq "A/E/F"
      expect(c1_2_1.group.name).to eq "A/E/F"
      expect(c1_2_1.depth).to eq 2
      expect(c1_2_1.basename).to eq g1_2_1.basename
      expect(c1_2_1.filename).to eq "#{g1.basename}/#{g1_2.basename}/#{g1_2_1.basename}"
      expect(c1_2_1.root.group.id).to eq g1.id
      expect(c1_2_1.parent.group.id).to eq g1_2.id
      expect(c1_2_1.children.map { |c| c.group.id }).to match_array []
      expect(c1_2_1.descendants.map { |c| c.group.id }).to match_array []

      expect(c1_2_2.name).to eq "G/H"
      expect(c1_2_2.full_name).to eq "A/E/G/H"
      expect(c1_2_2.group.name).to eq "A/E/G/H"
      expect(c1_2_2.depth).to eq 2
      expect(c1_2_2.basename).to eq g1_2_2.basename
      expect(c1_2_2.filename).to eq "#{g1.basename}/#{g1_2.basename}/#{g1_2_2.basename}"
      expect(c1_2_2.root.group.id).to eq g1.id
      expect(c1_2_2.parent.group.id).to eq g1_2.id
      expect(c1_2_2.children.map { |c| c.group.id }).to match_array []
      expect(c1_2_2.descendants.map { |c| c.group.id }).to match_array []
    end

    it do
      root = described_class.build(g1_1)

      expect(root.name).to eq "B"
      expect(root.full_name).to eq "B"
      expect(root.group.name).to eq "A/B"
      expect(root.depth).to eq 0
      expect(root.basename).to eq g1_1.basename
      expect(root.filename).to eq g1_1.basename
      expect(root.root.group.id).to eq g1_1.id
      expect(root.parent).to eq nil
      expect(root.children.map { |c| c.group.id }).to match_array [g1_1_1.id, g1_1_2.id]
      expect(root.descendants.map { |c| c.group.id }).to match_array [g1_1_1.id, g1_1_2.id]

      c1_1_1 = root.children.find { |c| c.group.id == g1_1_1.id }
      c1_1_2 = root.children.find { |c| c.group.id == g1_1_2.id }

      expect(c1_1_1.name).to eq "C"
      expect(c1_1_1.full_name).to eq "B/C"
      expect(c1_1_1.group.name).to eq "A/B/C"
      expect(c1_1_1.depth).to eq 1
      expect(c1_1_1.basename).to eq g1_1_1.basename
      expect(c1_1_1.filename).to eq "#{g1_1.basename}/#{g1_1_1.basename}"
      expect(c1_1_1.root.group.id).to eq g1_1.id
      expect(c1_1_1.parent.group.id).to eq g1_1.id
      expect(c1_1_1.children.map{ |c| c.group.id }).to match_array []
      expect(c1_1_1.descendants.map{ |c| c.group.id }).to match_array []

      expect(c1_1_2.name).to eq "D"
      expect(c1_1_2.full_name).to eq "B/D"
      expect(c1_1_2.group.name).to eq "A/B/D"
      expect(c1_1_2.depth).to eq 1
      expect(c1_1_2.basename).to eq g1_1_2.basename
      expect(c1_1_2.filename).to eq "#{g1_1.basename}/#{g1_1_2.basename}"
      expect(c1_1_2.root.group.id).to eq g1_1.id
      expect(c1_1_2.parent.group.id).to eq g1_1.id
      expect(c1_1_2.children.map{ |c| c.group.id }).to match_array []
      expect(c1_1_2.descendants.map{ |c| c.group.id }).to match_array []
    end
  end

  context "set exclude groups" do
    it do
      root = described_class.build(g1, [g1_1_1])
      expect(root.tree.map(&:full_name)).to match_array [g1, g1_1, g1_1_2, g1_2, g1_2_1, g1_2_2, g1_3].map(&:name)

      expect(root.children.map { |c| c.group.id }).to match_array [g1_1, g1_2, g1_3].map(&:id)
      expect(root.descendants.map { |c| c.group.id }).to match_array [g1_1, g1_1_2, g1_2, g1_2_1, g1_2_2, g1_3].map(&:id)

      c1_1 = root.children.find { |c| c.group.id == g1_1.id }
      expect(c1_1.children.map { |c| c.group.id }).to match_array [g1_1_2.id]
      expect(c1_1.descendants.map { |c| c.group.id }).to match_array [g1_1_2.id]
    end

    it do
      root = described_class.build(g1, [g1_1])
      expect(root.tree.map(&:full_name)).to match_array [g1, g1_2, g1_2_1, g1_2_2, g1_3].map(&:name)

      expect(root.children.map { |c| c.group.id }).to match_array [g1_2, g1_3].map(&:id)
      expect(root.descendants.map { |c| c.group.id }).to match_array [g1_2, g1_2_1, g1_2_2, g1_3].map(&:id)
    end

    it do
      root = described_class.build(g1, [g1_1, g1_2_1])
      expect(root.tree.map(&:full_name)).to match_array [g1, g1_2, g1_2_2, g1_3].map(&:name)

      expect(root.children.map { |c| c.group.id }).to match_array [g1_2, g1_3].map(&:id)
      expect(root.descendants.map { |c| c.group.id }).to match_array [g1_2, g1_2_2, g1_3].map(&:id)
    end

    it do
      root = described_class.build(g1, [g1])
      expect(root).to be nil
    end
  end
end
