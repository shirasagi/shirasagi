require 'spec_helper'

describe Sns::Message::Post, type: :model, dbscope: :example do
  let(:model) { described_class }
  let(:group) { create :ss_group }
  let!(:user1) { create :ss_user, group_ids: [group.id] }
  let!(:user2) { create :ss_user2, group_ids: [group.id] }
  let!(:user3) { create :ss_user3, group_ids: [group.id] }

  describe "validation" do
    it { expect(model.new.save).to be_falsey }
  end

  describe 'unseen' do
    let(:member_ids) { [user1.id, user2.id, user3.id] }
    let(:thread) { build(:sns_message_thread, member_ids: member_ids, text: 'text').recycle_create }
    let(:post) { create :sns_message_post, thread_id: thread.id, text: 'text' }

    it do
      expect(thread.unseen_member_ids).to eq [user2.id, user3.id]
      expect(Sns::Message::Post.where(thread_id: thread.id).size).to eq 1

      created = thread.updated
      expect(post.thread.updated).to be > created
    end
  end
end
