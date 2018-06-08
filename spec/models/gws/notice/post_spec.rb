require 'spec_helper'

describe Gws::Notice::Post, type: :model, dbscope: :example, tmpdir: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:folder1) { create(:gws_notice_folder, cur_site: site) }
  let(:folder2) { create(:gws_notice_folder, cur_site: site) }
  let(:file) { tmp_ss_file(contents: '0123456789', user: user) }
  let(:text) { unique_id }

  context 'basic creation' do
    subject { create :gws_notice_post, cur_site: site, cur_user: user, folder: folder1, text: text, file_ids: [ file.id ] }

    it do
      expect(subject.valid?).to be_truthy
    end
  end
end
