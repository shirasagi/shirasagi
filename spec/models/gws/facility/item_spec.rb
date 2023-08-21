require 'spec_helper'

describe Gws::Facility::Item, type: :model, dbscope: :example do
  let(:model) { described_class }
  let(:user) { gws_user }

  describe "validation" do
    it { expect(model.new.save).to be_falsey }
  end

  describe 'readable' do
    let(:item0) { create :gws_facility_item }
    let(:item1) { create :gws_facility_item, readable_group_ids: user.group_ids }
    let(:item2) { create :gws_facility_item, readable_member_ids: [user.id] }
    let(:item3) { create :gws_facility_item, readable_group_ids: [999] }
    let(:item4) { create :gws_facility_item, readable_member_ids: [999] }

    context 'without role' do
      before do
        user.gws_role_ids = nil
        user.save!
      end

      it do
        expect(item0.readable?(user)).to be_falsey
        expect(item1.readable?(user)).to be_falsey
        expect(item2.readable?(user)).to be_falsey
        expect(item3.readable?(user)).to be_falsey
        expect(item4.readable?(user)).to be_falsey
        expect(model.readable(user, site: gws_site).size).to eq 0
      end
    end

    context 'with role' do
      it do
        expect(item0.readable?(user)).to be_truthy
        expect(item1.readable?(user)).to be_truthy
        expect(item2.readable?(user)).to be_truthy
        expect(item3.readable?(user)).to be_falsey
        expect(item4.readable?(user)).to be_falsey
        expect(model.readable(user, site: gws_site).size).to eq 3
      end
    end
  end

  describe 'reservable' do
    let(:item0) { create :gws_facility_item }
    let(:item1) { create :gws_facility_item, reservable_group_ids: user.group_ids }
    let(:item2) { create :gws_facility_item, reservable_member_ids: [user.id] }
    let(:item3) { create :gws_facility_item, reservable_group_ids: [999] }
    let(:item4) { create :gws_facility_item, reservable_member_ids: [999] }

    it do
      expect(item0.reservable?(user)).to be_truthy
      expect(item1.reservable?(user)).to be_truthy
      expect(item2.reservable?(user)).to be_truthy
      expect(item3.reservable?(user)).to be_falsey
      expect(item4.reservable?(user)).to be_falsey
      expect(model.reservable(user).size).to eq 3
    end
  end
end
