require 'spec_helper'

RSpec.describe Gws::Board::Topic, type: :model, dbscope: :example do
  let(:post) { create(:gws_board_topic) }
  let(:user1) { create(:gws_user) }
  let(:user2) { create(:gws_user) }

  describe "#set_browsed!" do
    it do
      expect { post.set_browsed!(user1) }.not_to raise_error
      expect { post.set_browsed!(user2) }.not_to raise_error
      post.reload
      expect(post.browsed_users_hash[user1.id.to_s]).not_to be_nil
      expect(post.browsed_users_hash[user2.id.to_s]).not_to be_nil
    end
  end
end
