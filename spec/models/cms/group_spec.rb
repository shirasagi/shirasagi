require 'spec_helper'

describe Cms::Group, type: :model, dbscope: :example do
  context "blank params" do
    subject { described_class.new.valid? }
    it { expect(subject).to be_falsey }
  end

  context "default params" do
    subject { create :cms_group }
    it { expect(subject.errors.size).to eq 0 }
  end

  context "renaming" do
    let!(:root) { create(:cms_group) }
    let!(:child) { create(:cms_group, name: "#{root.name}/#{unique_id}") }
    let!(:new_name) { unique_id }

    it do
      old_name = root.name
      expect(child.name).to start_with("#{old_name}/")

      root.name = new_name
      root.save!

      child.reload
      expect(child.name).not_to start_with("#{old_name}/")
      expect(child.name).to start_with(new_name)
    end
  end

  describe "#trailing_name" do
    let!(:root) { create(:cms_group, name: 'AA') }

    context "group with parent" do
      subject { create(:cms_group, name: 'AA/BBB') }
      its(:trailing_name) { is_expected.to eq 'BBB' }
      its(:depth) { is_expected.to eq 1 }
    end

    context "group without parent" do
      subject { create(:cms_group, name: 'AA/HHH/IIII') }
      its(:trailing_name) { is_expected.to eq 'HHH/IIII' }
      its(:depth) { is_expected.to eq 1 }
    end
  end

  describe ".tree_sort" do
    before do
      create(:cms_group, name: 'AA', order: 10)
      create(:cms_group, name: 'AA/BBB')
      create(:cms_group, name: 'AA/CCC', order: 30)
      create(:cms_group, name: 'AA/BBB/DDDD', order: 40)
      create(:cms_group, name: 'AA/BBB/EEEE', order: 70)
      create(:cms_group, name: 'AA/CCC/FFFF', order: 50)
      create(:cms_group, name: 'AA/CCC/GGGG', order: 60)
      # lost child
      create(:cms_group, name: 'AA/HHH/IIII', order: 0)
    end

    context "without descendants" do
      subject { described_class.tree_sort.to_a }

      it do
        expect(subject[0].name).to eq 'AA'
        expect(subject[0].depth).to eq 0
        expect(subject[0].trailing_name).to eq 'AA'

        expect(subject[1].name).to eq 'AA/BBB'
        expect(subject[1].depth).to eq 1
        expect(subject[1].trailing_name).to eq 'BBB'

        expect(subject[2].name).to eq 'AA/BBB/DDDD'
        expect(subject[2].depth).to eq 2
        expect(subject[2].trailing_name).to eq 'DDDD'

        expect(subject[3].name).to eq 'AA/BBB/EEEE'
        expect(subject[3].depth).to eq 2
        expect(subject[3].trailing_name).to eq 'EEEE'

        expect(subject[4].name).to eq 'AA/CCC'
        expect(subject[4].depth).to eq 1
        expect(subject[4].trailing_name).to eq 'CCC'

        expect(subject[5].name).to eq 'AA/CCC/FFFF'
        expect(subject[5].depth).to eq 2
        expect(subject[5].trailing_name).to eq 'FFFF'

        expect(subject[6].name).to eq 'AA/CCC/GGGG'
        expect(subject[6].depth).to eq 2
        expect(subject[6].trailing_name).to eq 'GGGG'

        expect(subject[7].name).to eq 'AA/HHH/IIII'
        expect(subject[7].depth).to eq 1
        expect(subject[7].trailing_name).to eq 'HHH/IIII'
      end
    end

    context "with descendants of root group" do
      let(:root) { Cms::Group.find_by(name: 'AA') }
      subject { root.descendants.active.tree_sort(root_name: root.name).to_a }

      it do
        expect(subject[0].name).to eq 'AA/BBB'
        expect(subject[0].depth).to eq 0
        expect(subject[0].trailing_name).to eq 'BBB'

        expect(subject[1].name).to eq 'AA/BBB/DDDD'
        expect(subject[1].depth).to eq 1
        expect(subject[1].trailing_name).to eq 'DDDD'

        expect(subject[2].name).to eq 'AA/BBB/EEEE'
        expect(subject[2].depth).to eq 1
        expect(subject[2].trailing_name).to eq 'EEEE'

        expect(subject[3].name).to eq 'AA/CCC'
        expect(subject[3].depth).to eq 0
        expect(subject[3].trailing_name).to eq 'CCC'

        expect(subject[4].name).to eq 'AA/CCC/FFFF'
        expect(subject[4].depth).to eq 1
        expect(subject[4].trailing_name).to eq 'FFFF'

        expect(subject[5].name).to eq 'AA/CCC/GGGG'
        expect(subject[5].depth).to eq 1
        expect(subject[5].trailing_name).to eq 'GGGG'

        expect(subject[6].name).to eq 'AA/HHH/IIII'
        expect(subject[6].depth).to eq 0
        expect(subject[6].trailing_name).to eq 'HHH/IIII'
      end
    end

    context "with descendants of second depth group" do
      let(:second_depth_group) { Cms::Group.find_by(name: 'AA/BBB') }
      subject { second_depth_group.descendants.active.tree_sort(root_name: second_depth_group.name).to_a }

      it do
        expect(subject[0].name).to eq 'AA/BBB/DDDD'
        expect(subject[0].depth).to eq 0
        expect(subject[0].trailing_name).to eq 'DDDD'

        expect(subject[1].name).to eq 'AA/BBB/EEEE'
        expect(subject[1].depth).to eq 0
        expect(subject[1].trailing_name).to eq 'EEEE'
      end
    end

    context "with invalid root name" do
      subject { described_class.tree_sort(root_name: "#{unique_id}/#{unique_id}").to_a }

      it do
        expect(subject[0].name).to eq 'AA'
        expect(subject[0].depth).to eq 0
        expect(subject[0].trailing_name).to eq 'AA'

        expect(subject[1].name).to eq 'AA/BBB'
        expect(subject[1].depth).to eq 1
        expect(subject[1].trailing_name).to eq 'BBB'

        expect(subject[2].name).to eq 'AA/BBB/DDDD'
        expect(subject[2].depth).to eq 2
        expect(subject[2].trailing_name).to eq 'DDDD'

        expect(subject[3].name).to eq 'AA/BBB/EEEE'
        expect(subject[3].depth).to eq 2
        expect(subject[3].trailing_name).to eq 'EEEE'

        expect(subject[4].name).to eq 'AA/CCC'
        expect(subject[4].depth).to eq 1
        expect(subject[4].trailing_name).to eq 'CCC'

        expect(subject[5].name).to eq 'AA/CCC/FFFF'
        expect(subject[5].depth).to eq 2
        expect(subject[5].trailing_name).to eq 'FFFF'

        expect(subject[6].name).to eq 'AA/CCC/GGGG'
        expect(subject[6].depth).to eq 2
        expect(subject[6].trailing_name).to eq 'GGGG'

        expect(subject[7].name).to eq 'AA/HHH/IIII'
        expect(subject[7].depth).to eq 1
        expect(subject[7].trailing_name).to eq 'HHH/IIII'
      end
    end
  end

  describe ".to_options" do
    before do
      create(:cms_group, name: 'AA', order: 10)
      create(:cms_group, name: 'AA/BBB')
      create(:cms_group, name: 'AA/CCC', order: 30)
      create(:cms_group, name: 'AA/BBB/DDDD', order: 40)
      create(:cms_group, name: 'AA/BBB/EEEE', order: 70)
      create(:cms_group, name: 'AA/CCC/FFFF', order: 50)
      create(:cms_group, name: 'AA/CCC/GGGG', order: 60)
      # lost child
      create(:cms_group, name: 'AA/HHH/IIII', order: 0)
    end

    subject { described_class.tree_sort.to_options }
    it do
      expect(subject[0]).to eq [ 'AA', 1 ]
      expect(subject[1]).to eq [ '+---- BBB', 2 ]
      expect(subject[2]).to eq [ '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;+---- DDDD', 4 ]
      expect(subject[3]).to eq [ '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;+---- EEEE', 5 ]
      expect(subject[4]).to eq [ '+---- CCC', 3 ]
      expect(subject[5]).to eq [ '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;+---- FFFF', 6 ]
      expect(subject[6]).to eq [ '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;+---- GGGG', 7 ]
      expect(subject[7]).to eq [ '+---- HHH/IIII', 8 ]
    end
  end

  describe ".tree_sort with 2nd depth group" do
    before do
      create(:cms_group, name: 'A/AA', order: 10)
      create(:cms_group, name: 'A/AA/BBB')
      create(:cms_group, name: 'A/AA/CCC', order: 30, expiration_date: 1.day.ago)
      create(:cms_group, name: 'A/AA/BBB/DDDD', order: 40)
      create(:cms_group, name: 'A/AA/BBB/EEEE', order: 70)
      create(:cms_group, name: 'A/AA/CCC/FFFF', order: 50)
      create(:cms_group, name: 'A/AA/CCC/GGGG', order: 60)
      # lost child
      create(:cms_group, name: 'A/AA/HHH/IIII', order: 0)
    end

    context "without descendants" do
      subject { described_class.where(name: /^A\//).tree_sort.to_a }

      it do
        expect(subject[0].name).to eq 'A/AA'
        expect(subject[0].depth).to eq 0
        expect(subject[0].trailing_name).to eq 'A/AA'

        expect(subject[1].name).to eq 'A/AA/BBB'
        expect(subject[1].depth).to eq 1
        expect(subject[1].trailing_name).to eq 'BBB'

        expect(subject[2].name).to eq 'A/AA/BBB/DDDD'
        expect(subject[2].depth).to eq 2
        expect(subject[2].trailing_name).to eq 'DDDD'

        expect(subject[3].name).to eq 'A/AA/BBB/EEEE'
        expect(subject[3].depth).to eq 2
        expect(subject[3].trailing_name).to eq 'EEEE'

        expect(subject[4].name).to eq 'A/AA/CCC/FFFF'
        expect(subject[4].depth).to eq 1
        expect(subject[4].trailing_name).to eq 'CCC/FFFF'

        expect(subject[5].name).to eq 'A/AA/CCC/GGGG'
        expect(subject[5].depth).to eq 1
        expect(subject[5].trailing_name).to eq 'CCC/GGGG'

        expect(subject[6].name).to eq 'A/AA/HHH/IIII'
        expect(subject[6].depth).to eq 1
        expect(subject[6].trailing_name).to eq 'HHH/IIII'
      end
    end
  end
end
