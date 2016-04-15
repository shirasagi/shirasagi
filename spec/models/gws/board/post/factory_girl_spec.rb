require 'spec_helper'

RSpec.describe Gws::Board::Post, type: :model, dbscope: :example do
  describe "FactoryGirl test" do
    describe "board_post" do
      before { create :gws_board_post }
      it { expect(described_class.count).to eq 1 }
    end

    describe "board_topic" do
      let!(:topic) { create :gws_board_topic }
      it { expect(described_class.count).to eq 1 }
      it { expect(topic.parent_id).to be_nil }
    end

    describe "board_comment" do
      let!(:comment) { create :gws_board_comment }
      it { expect(described_class.count).to eq 2 }

      describe "parent" do
        subject { comment.parent }
        it { is_expected.not_to be_nil }
        it { is_expected.to be_a_kind_of described_class }
        it { expect(subject.parent).to be_nil }
      end
    end

    describe "board_comment_to_comment" do
      let!(:comment) { create :gws_board_comment_to_comment }
      it { expect(described_class.count).to eq 3 }

      describe "parent" do
        subject { comment.parent }
        it { is_expected.not_to be_nil }
        it { is_expected.to be_a_kind_of described_class }
        it { expect(subject.parent).not_to be_nil }
        it { expect(subject.parent.parent).to be_nil }
      end
    end
  end
end
