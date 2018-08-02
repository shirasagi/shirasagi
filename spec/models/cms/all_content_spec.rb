require 'spec_helper'

describe Cms::AllContent, type: :model, dbscope: :example do
  describe ".csv" do
    let(:site) { cms_site }
    let(:csv) { described_class.enum_csv(site) }

    describe "header line" do
      let(:header) { csv.to_a[0].encode('UTF-8').split(",") }
      it { expect(header[0]).to eq(I18n.t("all_content.page_id")) }
      it { expect(header[1]).to eq(I18n.t("all_content.node_id")) }
      it { expect(header[28]).to eq(I18n.t("all_content.updated")) }
    end

    describe "contents" do
      before do
        @page = create :cms_page
        @node = create :cms_node
      end

      let(:line1) { csv.to_a[1].encode('UTF-8').split(",") }
      let(:line2) { csv.to_a[2].encode('UTF-8').split(",") }

      it { expect(line1[6]).to eq @page.full_url }
      it { expect(line2[6]).to eq @node.full_url }
    end
  end

  describe ".valid_header?" do
    context "when given file as path string" do
      let(:path) { "#{Rails.root}/spec/fixtures/cms/all_contents_1.csv" }
      subject { Cms::AllContent.valid_header?(path) }
      it { is_expected.to be_truthy }
    end

    context "when given file as upload file" do
      let(:path) { "#{Rails.root}/spec/fixtures/cms/all_contents_1.csv" }
      subject do
        ::File.open(path, "rb") do |tempfile|
          f = ActionDispatch::Http::UploadedFile.new(
            filename: ::File.basename(path), type: "text/csv", name: "item[in_file]", tempfile: tempfile
          )
          Cms::AllContent.valid_header?(f)
        end
      end
      it { is_expected.to be_truthy }
    end

    context "when given invalid csv file" do
      let(:path) { "#{Rails.root}/spec/fixtures/facility/facility.csv" }
      subject { Cms::AllContent.valid_header?(path) }
      it { is_expected.to be_falsey }
    end

    context "when given png" do
      let(:path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
      subject { Cms::AllContent.valid_header?(path) }
      it { is_expected.to be_falsey }
    end
  end
end
