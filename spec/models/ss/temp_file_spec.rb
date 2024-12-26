require 'spec_helper'

describe SS::TempFile do
  describe "empty" do
    subject { described_class.new }
    its(:valid?) { is_expected.to be_falsey }
  end

  describe "factory girl" do
    subject { create :ss_temp_file }
    its(:valid?) { is_expected.to be_truthy }
  end

  describe ".create_empty!" do
    let(:name) { unique_id }
    let(:filename) { "#{name}.png" }
    let(:content_type) { SS::MimeType.find(filename, 'application/octet-stream') }

    context "without block" do
      it do
        file = described_class.create_empty!(name: name, filename: filename, content_type: content_type)

        expect(file.model).to eq 'ss/temp_file'
        expect(file.state).to eq 'closed'
        expect(file.name).to eq name
        expect(file.filename).to eq filename
        expect(file.content_type).to eq content_type
        expect(file.size).to eq 0
        expect(File.exist?(file.path)).to be_truthy
        expect(file.errors).to be_empty
      end
    end

    context "with block" do
      it do
        file = described_class.create_empty!(name: name, filename: filename, content_type: content_type) do |file|
          FileUtils.cp("#{Rails.root}/spec/fixtures/ss/logo.png", file.path)
        end

        expect(file.model).to eq 'ss/temp_file'
        expect(file.state).to eq 'closed'
        expect(file.name).to eq name
        expect(file.filename).to eq filename
        expect(file.content_type).to eq content_type
        expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
        expect(File.exist?(file.path)).to be_truthy
        expect(file.errors).to be_empty
      end
    end
  end
end
