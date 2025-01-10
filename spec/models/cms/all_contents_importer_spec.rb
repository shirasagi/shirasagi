require 'spec_helper'

describe Cms::AllContentsImporter, type: :model, dbscope: :example do
  describe ".valid_csv?" do
    context "when given file as path string" do
      let(:path) { "#{Rails.root}/spec/fixtures/cms/all_contents_1.csv" }
      subject { described_class.valid_csv?(path) }
      it { is_expected.to be_truthy }
    end

    context "when given file as upload file" do
      let(:path) { "#{Rails.root}/spec/fixtures/cms/all_contents_1.csv" }
      subject do
        ::File.open(path, "rb") do |tempfile|
          f = ActionDispatch::Http::UploadedFile.new(
            filename: ::File.basename(path), type: "text/csv", name: "item[in_file]", tempfile: tempfile
          )
          described_class.valid_csv?(f)
        end
      end
      it { is_expected.to be_truthy }
    end

    context "when given invalid csv file" do
      let(:path) { "#{Rails.root}/spec/fixtures/facility/facility.csv" }
      subject { described_class.valid_csv?(path) }
      it { is_expected.to be_falsey }
    end

    context "when given png" do
      let(:path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
      subject { described_class.valid_csv?(path) }
      it { is_expected.to be_falsey }
    end
  end
end
