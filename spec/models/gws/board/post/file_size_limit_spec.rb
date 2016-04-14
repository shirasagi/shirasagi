require 'spec_helper'

RSpec.describe Gws::Board::Post, type: :model, dbscope: :example, tmpdir: true do
  describe "file size limit test" do
    let(:site) { gws_site }
    let(:user) { gws_user }
    let(:file_size_per_topic) { 20 }
    let(:file_size_per_post) { 10 }

    before do
      site.board_file_size_per_topic = file_size_per_topic
      site.board_file_size_per_post = file_size_per_post
      site.save!
    end

    context "with single topic" do
      let(:topic) { create :gws_board_topic, cur_site: site, cur_user: user }

      context "within limit" do
        let(:file) { tmp_ss_file(contents: '0123456789', user: user) }

        it do
          topic.file_ids = [ file.id ]
          expect(topic.valid?).to be_truthy
          expect(topic.errors.empty?).to be_truthy
        end
      end

      context "without limit" do
        let(:file) { tmp_ss_file(contents: '01234567891', user: user) }

        it do
          topic.file_ids = [ file.id ]
          expect(topic.valid?).to be_falsey
          expect(topic.errors.empty?).to be_falsey
        end
      end
    end

    context "with topic's comment" do
      let(:file) { tmp_ss_file(contents: '0123456789', user: user) }
      let(:topic) { create :gws_board_topic, cur_site: site, cur_user: user, file_ids: [ file.id ] }
      let(:comment) { create :gws_board_comment, cur_site: site, cur_user: user, parent: topic }

      context "within limit" do
        it do
          expect(topic.descendants_files_count).to eq 1
          expect(topic.descendants_total_file_size).to eq 10

          comment.file_ids = [ file.id ]
          expect(comment.valid?).to be_truthy
          expect(comment.errors.empty?).to be_truthy
        end
      end

      context "without limit" do
        let(:file2) { tmp_ss_file(contents: '01234567891', user: user) }

        it do
          comment.file_ids = [ file2.id ]
          expect(comment.valid?).to be_falsey
          expect(comment.errors.empty?).to be_falsey
        end
      end
    end

    context "without board_file_size_per_topic" do
      let(:topic) { create :gws_board_topic, cur_site: site, cur_user: user }

      before do
        topic.file_ids = [ tmp_ss_file(contents: '0123456789', user: user).id ]
        topic.save!

        file = tmp_ss_file(contents: '0123456789', user: user)
        create(:gws_board_comment, cur_site: site, cur_user: user, parent: topic, file_ids: [ file.id ])
        topic.reload
      end

      it do
        # before exam, we should check current file size is just equal to topic's limit.
        expect(topic.descendants_total_file_size).to eq file_size_per_topic

        # this one exceeds limits
        file = tmp_ss_file(contents: '0123456789', user: user)
        comment = create(:gws_board_comment, cur_site: site, cur_user: user, parent: topic)
        comment.file_ids = [ file.id ]
        expect(comment.valid?).to be_falsey
        expect(comment.errors.empty?).to be_falsey
      end
    end
  end
end
