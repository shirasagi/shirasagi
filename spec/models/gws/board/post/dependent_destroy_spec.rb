require 'spec_helper'

RSpec.describe Gws::Board::Post, type: :model, dbscope: :example do
  describe "dependent destroy" do
    context "topic > comment" do
      let!(:comment) { create :gws_board_comment }
      subject { comment.parent.destroy }
      it { expect { subject }.to change { described_class.count }.by(-2) }
    end

    context "topic > comment > comment" do
      let!(:comment) { create :gws_board_comment_to_comment }

      context "destroy parent" do
        subject { comment.parent.destroy }
        it { expect { subject }.to change { described_class.count }.by(-2) }
      end

      context "destroy parent of parent" do
        subject { comment.parent.parent.destroy }
        it { expect { subject }.to change { described_class.count }.by(-3) }
      end
    end
  end
end
