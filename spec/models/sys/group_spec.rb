require 'spec_helper'

describe Sys::Group do
  subject(:model) { Sys::Group }
  subject(:factory) { :ss_group }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#gws_use" do
    let!(:group1) { create(:ss_group, name: unique_id, gws_use: nil) }
    let!(:group2) { create(:ss_group, name: unique_id, gws_use: "") }
    let!(:group3) { create(:ss_group, name: unique_id, gws_use: "enabled") }
    let!(:group4) { create(:ss_group, name: unique_id, gws_use: "disabled") }
    let!(:group5) { create(:ss_group, name: unique_id) }

    before do
      group5.set(gws_use: unique_id)
    end

    it do
      expect(group1.gws_use?).to be_truthy
      expect(group2.gws_use?).to be_truthy
      expect(group3.gws_use?).to be_truthy
      expect(group4.gws_use?).to be_falsey
      expect(group5.gws_use?).to be_truthy

      criteria = Sys::Group.all.in(id: [group1.id, group2.id, group3.id, group4.id, group5.id]).and_gws_use
      expect(criteria.count).to eq 4
      expect(criteria.pluck(:id)).to include(group1.id, group2.id, group3.id, group5.id)
    end
  end
end
