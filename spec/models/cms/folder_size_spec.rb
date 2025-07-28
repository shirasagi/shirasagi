require 'spec_helper'

describe Cms::FolderSize, type: :model, dbscope: :example do
  describe ".csv" do
    let(:site) { cms_site }
    let(:csv) { described_class.enum_csv(site) }

    describe "header line" do
      let(:header) { csv.to_a[0].encode('UTF-8').split(",") }
      it { expect(header[0]).to eq(I18n.t("folder_size.name")) }
      it { expect(header[1]).to eq(I18n.t("folder_size.index_name")) }
      it { expect(header[10]).to eq(I18n.t("folder_size.released")) }
    end

    describe "contents" do
      let!(:folder1) { create :cms_node, filename: "docs/test" }
      let!(:folder2) { create :cms_node, filename: "calendar/test/test" }
      let!(:folder3) { create :cms_node, filename: "css" }
      let!(:folder4) { create :cms_node, filename: "garbage/category/c3" }
      let(:line1) { csv.to_a[1].encode('UTF-8').split(",") }
      let(:line2) { csv.to_a[2].encode('UTF-8').split(",") }
      let(:line3) { csv.to_a[3].encode('UTF-8').split(",") }
      let(:line4) { csv.to_a[4].encode('UTF-8').split(",") }

      it { expect(line1[2]).to match(/^docs/) }
      it { expect(line2[2]).to match(/^calendar/) }
      it { expect(line3[2]).to match(/^css/) }
      it { expect(line4[2]).to match(/^garbage/) }
    end
  end

  describe ".valid_header?" do
    context "when given file as path string" do
      let(:path) { "#{Rails.root}/spec/fixtures/cms/folder_sizes_1.csv" }
      subject { Cms::FolderSize.valid_header?(path) }
      it { is_expected.to be_truthy }
    end

    context "when given file as upload file" do
      let(:path) { "#{Rails.root}/spec/fixtures/cms/folder_sizes_1.csv" }
      subject do
        ::File.open(path, "rb") do |tempfile|
          f = ActionDispatch::Http::UploadedFile.new(
            filename: ::File.basename(path), type: "text/csv", name: "item[in_file]", tempfile: tempfile
          )
          Cms::FolderSize.valid_header?(f)
        end
      end
      it { is_expected.to be_truthy }
    end

    context "when given invalid csv file" do
      let(:path) { "#{Rails.root}/spec/fixtures/facility/facility.csv" }
      subject { Cms::FolderSize.valid_header?(path) }
      it { is_expected.to be_falsey }
    end

    context "when given png" do
      let(:path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
      subject { Cms::FolderSize.valid_header?(path) }
      it { is_expected.to be_falsey }
    end
  end
end
