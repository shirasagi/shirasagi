require 'spec_helper'

RSpec.describe Gws::Share::File, type: :model, dbscope: :example, tmpdir: true do
  describe "file size limit test" do
    let(:site) { gws_site }
    let(:user) { gws_user }
    let(:max_file_size) { 10 }

    before do
      site.share_max_file_size = max_file_size
      site.save!
    end

    context "within limit" do
      let(:file) { tmpfile { |file| file.write('0123456789') } }
      let(:up) { Fs::UploadedFile.create_from_file(file, basename: 'spec', content_type: 'application/octet-stream') }
      subject { create(:gws_share_file, cur_site: site, cur_user: user, in_file: up) }

      it do
        expect(subject.valid?).to be_truthy
        expect(subject.errors.empty?).to be_truthy
      end
    end

    context "without limit" do
      let(:file) { tmpfile { |file| file.write('01234567890') } }
      let(:up) { Fs::UploadedFile.create_from_file(file, basename: 'spec', content_type: 'application/octet-stream') }
      subject { build(:gws_share_file, cur_site: site, cur_user: user, in_file: up) }

      it do
        expect(subject.valid?).to be_falsey
        expect(subject.errors.empty?).to be_falsey
      end
    end
  end
end
