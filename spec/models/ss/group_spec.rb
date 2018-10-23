require 'spec_helper'

describe SS::Group, type: :model, dbscope: :example do
  context "blank params" do
    subject { described_class.new.valid? }
    it { expect(subject).to be_falsey }
  end

  context "default params" do
    subject { create :ss_group }
    it { expect(subject.errors.size).to eq 0 }
  end

  context "renaming" do
    let!(:root) { create(:ss_group) }
    let!(:child) { create(:ss_group, name: "#{root.name}/#{unique_id}") }
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

  context ".descendants" do
    let!(:root) { create(:ss_group) }
    let!(:group1) { create(:ss_group, name: "#{root.name}/#{unique_id}") }
    let!(:group11) { create(:ss_group, name: "#{group1.name}/#{unique_id}") }
    let!(:group12) { create(:ss_group, name: "#{group1.name}/#{unique_id}") }
    let!(:group2) { create(:ss_group, name: "#{root.name}/#{unique_id}") }
    let!(:group21) { create(:ss_group, name: "#{group2.name}/#{unique_id}") }
    let!(:group22) { create(:ss_group, name: "#{group2.name}/#{unique_id}") }

    it do
      ids = root.descendants.pluck(:id)
      expect(ids).to have(6).items
      expect(ids).to include(group1.id, group11.id, group12.id, group2.id, group21.id, group22.id)
    end

    it do
      ids = group1.descendants.pluck(:id)
      expect(ids).to have(2).items
      expect(ids).to include(group11.id, group12.id)
    end
  end

  context ".descendants_and_self" do
    let!(:root) { create(:ss_group) }
    let!(:group1) { create(:ss_group, name: "#{root.name}/#{unique_id}") }
    let!(:group11) { create(:ss_group, name: "#{group1.name}/#{unique_id}") }
    let!(:group12) { create(:ss_group, name: "#{group1.name}/#{unique_id}") }
    let!(:group2) { create(:ss_group, name: "#{root.name}/#{unique_id}") }
    let!(:group21) { create(:ss_group, name: "#{group2.name}/#{unique_id}") }
    let!(:group22) { create(:ss_group, name: "#{group2.name}/#{unique_id}") }

    it do
      ids = root.descendants_and_self.pluck(:id)
      expect(ids).to have(7).items
      expect(ids).to include(root.id, group1.id, group11.id, group12.id, group2.id, group21.id, group22.id)
    end

    it do
      ids = group1.descendants_and_self.pluck(:id)
      expect(ids).to have(3).items
      expect(ids).to include(group1.id, group11.id, group12.id)
    end
  end
end
