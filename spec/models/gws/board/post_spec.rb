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

  describe "mode and permit_comment field validations" do
    it { expect(build(:gws_board_topic,   mode: nil)          ).not_to be_valid }
    it { expect(build(:gws_board_comment, mode: nil)          ).to     be_valid }
    it { expect(build(:gws_board_topic,   permit_comment: nil)).not_to be_valid }
    it { expect(build(:gws_board_comment, permit_comment: nil)).to     be_valid }
  end

  describe "descendants_updated field" do
    describe "set before save" do
      context "when creating" do
        let(:post) { build :gws_board_post }
        it do
          expect { post.save }
            .to change { post.descendants_updated }.from(nil)
        end

        describe "it is same to updated field" do
          before { post.save }
          it { expect(post.descendants_updated).to eq_as_time post.updated }
        end
      end

      context "when updating" do
        let(:post) { create :gws_board_post }
        before { post.text += 'added text' }
        it { expect { post.save }.not_to change { post.descendants_updated } }

        describe "it is same to updated field" do
          before { post.save }
          it { expect(post.descendants_updated).not_to eq_as_time post.updated }
        end
      end
    end

    describe "of parent post" do
      let!(:topic_id) { create(:gws_board_topic).id }

      def topic
        described_class.find topic_id
      end

      context "when creating a comment" do
        it do
          expect { create :gws_board_comment, parent: topic }
            .to change { topic.descendants_updated }
        end
      end

      context "when creating a comment to comment" do
        let!(:comment_id) { create(:gws_board_comment, parent: topic).id }

        def comment
          described_class.find comment_id
        end

        it do
          expect { create :gws_board_comment, parent: comment }
            .not_to change { comment.descendants_updated }
        end

        it do
          expect { create :gws_board_comment, parent: comment }
            .to change { topic.descendants_updated }
        end
      end
    end
  end

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

  describe "#comment?" do
    it { expect(build(:gws_board_topic).comment?).to be_falsy }
    it { expect(build(:gws_board_comment).comment?).to be_truthy }
  end

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

  describe "topic scope" do
    subject { described_class.topic }
    let!(:topic) { create :gws_board_topic }
    let!(:comment) { create :gws_board_comment }
    it { is_expected.to include(topic) }
    it { is_expected.not_to include(comment) }
  end

  describe "comment scope" do
    subject { described_class.comment }
    let!(:topic) { create :gws_board_topic }
    let!(:comment) { create :gws_board_comment }
    it { is_expected.not_to include(topic) }
    it { is_expected.to include(comment) }
  end
end
