require 'spec_helper'

describe Sns::Message::Thread, type: :model, dbscope: :example do
  let(:model) { described_class }
  let(:group) { create :ss_group }
  let!(:user1) { create :ss_user, group_ids: [group.id] }
  let!(:user2) { create :ss_user2, group_ids: [group.id] }
  let!(:user3) { create :ss_user3, group_ids: [group.id] }
  let!(:user4) { create :ss_user4, group_ids: [group.id] }

  describe "validation" do
    it { expect(model.new.save).to be_falsey }
  end

  describe 'only_members' do
    let(:member_ids) { [user1.id, user2.id] }
    let(:item) { create :sns_message_thread, member_ids: member_ids }
    let(:recycle) { build :sns_message_thread, member_ids: member_ids, text: 'text' }

    it 'permission' do
      expect(item.allowed?(:read, user1)).to be_truthy
      expect(item.allowed?(:edit, user1)).to be_falsey
      expect(item.allowed?(:read, user2)).to be_truthy
      expect(item.allowed?(:edit, user2)).to be_falsey
      expect(item.allowed?(:read, user4)).to be_falsey
      expect(item.allowed?(:edit, user4)).to be_falsey
    end

    it 'attributes' do
      expect(item.members_type).to eq 'only'
      expect(item.editable_members?).to be_falsey
      expect(item.active_member_ids).to eq [user1.id, user2.id]
    end

    it 'recycle' do
      item_id = item.id
      expect(recycle.recycle_create.id).to eq item_id
    end
  end

  describe 'many_members' do
    let(:member_ids) { [user1.id, user2.id, user3.id] }
    let(:item) { create :sns_message_thread, member_ids: member_ids }
    let(:recycle) { build :sns_message_thread, member_ids: member_ids, text: 'text' }

    it 'attributes' do
      expect(item.members_type).to eq 'many'
      expect(item.editable_members?).to be_truthy
      expect(item.active_member_ids).to eq [user1.id, user2.id, user3.id]
    end

    it 'permission' do
      expect(item.allowed?(:read, user1)).to be_truthy
      expect(item.allowed?(:edit, user1)).to be_truthy
      expect(item.allowed?(:read, user2)).to be_truthy
      expect(item.allowed?(:edit, user2)).to be_truthy
      expect(item.allowed?(:read, user4)).to be_falsey
      expect(item.allowed?(:edit, user4)).to be_falsey
    end

    it 'recycle' do
      item_id = item.id
      expect(recycle.recycle_create.id).not_to eq item_id
    end
  end
end
