require 'spec_helper'

describe Gws::Notice::Post, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:folder1) { create(:gws_notice_folder, cur_site: site) }
  let(:folder2) { create(:gws_notice_folder, cur_site: site) }
  let(:file1) { tmp_ss_file(contents: unique_id * rand(1..10), user: user) }
  let(:file2) { tmp_ss_file(contents: unique_id * rand(1..10), user: user) }
  let(:name) { unique_id * rand(1..3) }
  let(:text1) { unique_id * rand(1..10) }
  let(:text2) { unique_id * rand(1..10) }

  context 'basic creation' do
    subject do
      create(:gws_notice_post, cur_site: site, cur_user: user, folder: folder1, name: name, text: text1, file_ids: [ file1.id ])
    end

    it do
      expect(subject.valid?).to be_truthy
      expect(subject.folder).to eq folder1
      expect(subject.name).to eq name
      expect(subject.text).to eq text1

      folder1.reload
      expect(folder1.notice_total_body_size).to eq text1.length
      expect(folder1.notice_total_file_size).to eq file1.size
    end
  end

  context 'resource limitation' do
    let(:base_notice_total_body_size) { rand(1..100) }
    let(:base_notice_total_file_size) { rand(1..100) }

    before do
      folder1.set(notice_total_body_size: base_notice_total_body_size, notice_total_file_size: base_notice_total_file_size)
      folder2.set(notice_total_body_size: base_notice_total_body_size, notice_total_file_size: base_notice_total_file_size)
    end

    context 'when text is modified' do
      subject do
        create(:gws_notice_post, cur_site: site, cur_user: user, folder: folder1, name: name, text: text1, file_ids: [ file1.id ])
      end

      before do
        subject.text = text2
        subject.save!
      end

      it do
        expect(subject.valid?).to be_truthy
        expect(subject.folder).to eq folder1
        expect(subject.name).to eq name
        expect(subject.text).to eq text2

        folder1.reload
        expect(folder1.notice_total_body_size).to eq base_notice_total_body_size + text2.length
        expect(folder1.notice_total_file_size).to eq base_notice_total_file_size + file1.size
      end
    end

    context 'when file is added' do
      subject do
        create(:gws_notice_post, cur_site: site, cur_user: user, folder: folder1, name: name, text: text1, file_ids: [ file1.id ])
      end

      before do
        subject.file_ids = [ file1.id, file2.id ]
        subject.save!
      end

      it do
        expect(subject.valid?).to be_truthy
        expect(subject.folder).to eq folder1
        expect(subject.name).to eq name
        expect(subject.text).to eq text1

        folder1.reload
        expect(folder1.notice_total_body_size).to eq base_notice_total_body_size + text1.length
        expect(folder1.notice_total_file_size).to eq base_notice_total_file_size + file1.size + file2.size
      end
    end

    context 'when file is removed' do
      subject do
        create(:gws_notice_post, cur_site: site, cur_user: user, folder: folder1, name: name, text: text1, file_ids: [ file1.id ])
      end

      before do
        subject.file_ids = []
        subject.save!
      end

      it do
        expect(subject.valid?).to be_truthy
        expect(subject.folder).to eq folder1
        expect(subject.name).to eq name
        expect(subject.text).to eq text1

        folder1.reload
        expect(folder1.notice_total_body_size).to eq base_notice_total_body_size + text1.length
        expect(folder1.notice_total_file_size).to eq base_notice_total_file_size
      end
    end

    context 'when a notice moves to other folder' do
      subject do
        create(:gws_notice_post, cur_site: site, cur_user: user, folder: folder1, name: name, text: text1, file_ids: [ file1.id ])
      end

      before do
        subject.folder = folder2
        subject.save!
      end

      it do
        expect(subject.valid?).to be_truthy
        expect(subject.folder).to eq folder2
        expect(subject.name).to eq name
        expect(subject.text).to eq text1

        folder1.reload
        expect(folder1.notice_total_body_size).to eq base_notice_total_body_size
        expect(folder1.notice_total_file_size).to eq base_notice_total_file_size

        folder2.reload
        expect(folder2.notice_total_body_size).to eq base_notice_total_body_size + text1.length
        expect(folder2.notice_total_file_size).to eq base_notice_total_file_size + file1.size
      end
    end
  end
end
