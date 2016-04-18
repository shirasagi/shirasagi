require 'spec_helper'

RSpec.describe Gws::Board::Post, type: :model, dbscope: :example do
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
        it { expect { post.save }.to change { post.descendants_updated } }

        describe "it is same to updated field" do
          before { post.save }
          it { expect(post.descendants_updated).to eq_as_time post.updated }
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
end
