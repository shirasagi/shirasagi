require 'spec_helper'

RSpec.describe Gws::Board::Post, type: :model, dbscope: :example, tmpdir: true do
  describe "file size limit test" do
    let(:site) { gws_site }

    before do
      site.board_file_size_per_topic = 20
      site.board_file_size_per_post = 10
      site.save!
    end

    context "with single topic" do
      let(:topic) { create :gws_board_topic }

      context "within limit" do
        let(:file) { tmp_ss_file(contents: '0123456789') }

        it do
          topic.file_ids = [ file.id ]
          expect(topic.valid?).to be_truthy
          expect(topic.errors.empty?).to be_truthy
        end
      end

      context "without limit" do
        let(:file) { tmp_ss_file(contents: '01234567891') }

        it do
          topic.file_ids = [ file.id ]
          expect(topic.valid?).to be_falsey
          expect(topic.errors.empty?).to be_falsey
        end
      end
    end

    context "with topic's comment" do
      let(:file) { tmp_ss_file(contents: '0123456789') }
      let(:topic) { create :gws_board_topic, file_ids: [ file.id ] }
      let(:comment) { create :gws_board_comment, parent: topic }

      context "within limit" do
        it do
          comment.file_ids = [ file.id ]
          expect(comment.valid?).to be_truthy
          expect(comment.errors.empty?).to be_truthy
        end
      end

      context "without limit" do
        let(:file2) { tmp_ss_file(contents: '01234567891') }

        it do
          comment.file_ids = [ file2.id ]
          expect(comment.valid?).to be_falsey
          expect(comment.errors.empty?).to be_falsey
        end
      end
    end
  end
end
