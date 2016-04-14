require 'spec_helper'

RSpec.describe Gws::Board::Post, type: :model, dbscope: :example, tmpdir: true do
  describe "descendants_files_count and descendants_total_file_size" do
    let(:user) { gws_user }

    context "with only topic" do
      context "with no attached files" do
        subject { create(:gws_board_topic, cur_user: user) }

        its(:descendants_files_count) { is_expected.to eq 0 }
        its(:descendants_total_file_size) { is_expected.to eq 0 }
      end

      context "with single attached file" do
        let(:file) { tmp_ss_file(contents: '0123456789', user: user) }
        subject { create :gws_board_topic, cur_user: user, file_ids: [ file.id ] }

        its(:file_ids) { is_expected.to eq [ file.id ] }
        its(:descendants_files_count) { is_expected.to eq 1 }
        its(:descendants_total_file_size) { is_expected.to eq file.size }
      end

      context "with 10 attached files having random size" do
        let(:file0) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file1) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file2) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file3) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file4) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file5) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file6) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file7) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file8) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file9) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:files) { [ file0, file1, file2, file3, file4, file5, file6, file7, file8, file9 ] }
        let(:file_ids) { files.map(&:id) }
        let(:total_file_size) { files.map(&:size).inject(:+) }
        subject { create :gws_board_topic, cur_user: user, file_ids: file_ids }

        its(:file_ids) { is_expected.to eq file_ids }
        its(:descendants_files_count) { is_expected.to eq files.length }
        its(:descendants_total_file_size) { is_expected.to eq total_file_size }
      end
    end

    context "with one topic and one comment" do
      context "with no attached files" do
        subject { create(:gws_board_topic, cur_user: user) }

        before do
          create(:gws_board_comment, parent: subject, cur_user: user)
          subject.reload
        end

        its(:descendants_files_count) { is_expected.to eq 0 }
        its(:descendants_total_file_size) { is_expected.to eq 0 }
      end

      context "with single attached file" do
        subject { create(:gws_board_topic, cur_user: user) }
        let(:file) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }

        before do
          create(:gws_board_comment, parent: subject, file_ids: [ file.id ])
          subject.reload
        end

        its(:descendants_files_count) { is_expected.to eq 1 }
        its(:descendants_total_file_size) { is_expected.to eq file.size }
      end

      context "with 10 attached files having random size" do
        let(:file0) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file1) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file2) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file3) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file4) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file5) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file6) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file7) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file8) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:file9) { tmp_ss_file(contents: '0' * (1 + rand(10)), user: user) }
        let(:files) { [ file0, file1, file2, file3, file4, file5, file6, file7, file8, file9 ] }
        let(:file_ids) { files.map(&:id) }
        let(:total_file_size) { files.map(&:size).inject(:+) }
        subject { create(:gws_board_topic, cur_user: user) }

        before do
          create(:gws_board_comment, parent: subject, file_ids: file_ids)
          subject.reload
        end

        its(:descendants_files_count) { is_expected.to eq files.length }
        its(:descendants_total_file_size) { is_expected.to eq total_file_size }
      end
    end

    context "with one topic and many comments" do
      context "with no attached files" do
        subject { create(:gws_board_topic, cur_user: user) }

        before do
          rand(10).times do
            create(:gws_board_comment, parent: subject, cur_user: user)
          end
          subject.reload
        end

        its(:descendants_files_count) { is_expected.to eq 0 }
        its(:descendants_total_file_size) { is_expected.to eq 0 }
      end

      context "with 10 attached files having random size" do
        subject { create(:gws_board_topic, cur_user: user) }

        before do
          @files = []
          (1 + rand(10)).times do
            files = []
            (1 + rand(10)).times do
              files << tmp_ss_file(contents: '0' * (1 + rand(10)), user: user)
            end

            create(:gws_board_comment, parent: subject, file_ids: files.map(&:id))
            @files += files
          end
          subject.reload
        end

        its(:descendants_files_count) { is_expected.to eq @files.length }
        its(:descendants_total_file_size) { is_expected.to eq @files.map(&:size).inject(:+) }
      end
    end

    context "ss file の変な仕様: 所有権のないファイルを attach してみる" do
      let(:file) { tmp_ss_file(contents: '0123456789') }
      subject { create :gws_board_topic, cur_user: user, file_ids: [ file.id ] }

      its(:file_ids) { is_expected.to eq [] }
      its(:descendants_files_count) { is_expected.to eq 0 }
      its(:descendants_total_file_size) { is_expected.to eq 0 }
    end
  end
end
