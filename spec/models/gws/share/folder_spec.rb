require 'spec_helper'

RSpec.describe Gws::Share::Folder, type: :model, dbscope: :example do
  describe "with factory" do
    context "blank params" do
      subject { Gws::Share::Folder.new(cur_site: gws_site, cur_user: gws_user).valid? }
      it { expect(subject).to be_falsey }
    end

    context "default params" do
      subject { create(:gws_share_folder) }
      it { expect(subject.errors.size).to eq 0 }
    end
  end

  describe ".share_max_file_size" do
    subject { create(:gws_share_folder, share_max_file_size: 100 * 1_024) }
    let!(:category) { create :gws_share_category }
    let!(:file) { create :gws_share_file, folder_id: subject.id, category_ids: [category.id] }

    before do
      subject.reload
      expect(subject.files.count).to eq 1
    end

    context "exactly same with file.size" do
      it do
        subject.share_max_file_size = file.size
        subject.validate
        expect(subject).to have(0).errors_on(:base)
      end
    end

    context "below file.size" do
      it do
        subject.share_max_file_size = file.size - 1
        subject.validate
        expect(subject).to have(1).errors_on(:base)

        msg = I18n.t(
          "mongoid.errors.models.gws/share/folder.file_size_exceeds_folder_limit",
          size: file.size.to_s(:human_size), limit: subject.share_max_file_size.to_s(:human_size)
        )
        expect(subject.errors[:base]).to include(msg)
      end
    end
  end
end
