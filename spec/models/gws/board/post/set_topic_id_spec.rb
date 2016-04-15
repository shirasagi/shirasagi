require 'spec_helper'

RSpec.describe Gws::Board::Post, type: :model, dbscope: :example do
  describe "#set_topic_id" do
    subject { post.topic_id }

    context "topic" do
      let(:post) { create :gws_board_topic }
      it { is_expected.to be_nil }
    end

    context "comment" do
      let(:post) { create :gws_board_comment }
      it { is_expected.to eq post.parent.id }
      it { is_expected.to eq post.root_post.id }
    end

    context "comment to comment" do
      let(:post) { create :gws_board_comment_to_comment }
      it { is_expected.to eq post.root_post.id }
    end
  end
end
