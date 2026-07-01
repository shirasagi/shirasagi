require 'spec_helper'

RSpec.describe Gws::Share::File, type: :model, dbscope: :example do
  let(:model) { described_class }

  describe "topic" do
    context "blank params" do
      subject { Gws::Share::File.new(cur_site: gws_site, cur_user: gws_user).valid? }
      it { expect(subject).to be_falsey }
    end

    context "default params" do
      subject { create(:gws_share_file) }
      it { expect(subject.errors.size).to eq 0 }
    end

    context "when in_file is missing" do
      subject { build(:gws_share_file, in_file: nil).valid? }
      it { expect(subject).to be_falsey }
    end
  end

  describe "#file_icon_name" do
    # 拡張子 → ファイル一覧アイコン(ss-icon-*)のグリフ名を返す。
    # filename を設定すれば extname 経由で判定されるため、アップロードや保存は不要。
    def icon_name_for(filename)
      item = Gws::Share::File.new
      item.filename = filename
      item.file_icon_name
    end

    it "returns the extension itself for delivered types" do
      expect(icon_name_for("report.pdf")).to eq "pdf"
      expect(icon_name_for("sheet.xlsx")).to eq "xlsx"
    end

    it "downcases the extension" do
      expect(icon_name_for("REPORT.PDF")).to eq "pdf"
    end

    it "falls back to 'other' for unknown extensions" do
      expect(icon_name_for("archive.tar")).to eq "other"
    end

    it "falls back to 'other' when there is no extension" do
      expect(icon_name_for("README")).to eq "other"
    end

    it "maps every delivered extension to itself" do
      Gws::Share::File::FILE_ICON_EXTNAMES.each do |ext|
        expect(icon_name_for("file.#{ext}")).to eq ext
      end
    end
  end
end
