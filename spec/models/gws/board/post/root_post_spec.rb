require 'spec_helper'

RSpec.describe Gws::Board::Post, type: :model, dbscope: :example do
  describe "#root_post" do
    subject { post.root_post }

    context "topic" do
      let(:post) { build(:gws_board_topic) }
      it { is_expected.to eq post }
    end

    context "comment" do
      let(:post) { build(:gws_board_comment) }
      it { is_expected.to eq post.parent }
    end

    context "comment to comment" do
      let(:post) { build(:gws_board_comment_to_comment) }
      it { is_expected.to eq post.parent.parent }
    end
  end
end
