require 'spec_helper'

describe Gws::Tabular::File::DownloadParam, type: :model, dbscope: :example do
  subject { described_class.new }

  describe "#format" do
    it "defaults to csv" do
      expect(subject.format).to eq "csv"
    end

    it "accepts csv" do
      subject.format = "csv"
      subject.encoding = "UTF-8"
      expect(subject.valid?).to be_truthy
    end

    it "accepts zip" do
      subject.format = "zip"
      subject.encoding = "UTF-8"
      expect(subject.valid?).to be_truthy
    end

    it "rejects unknown format" do
      subject.format = "xlsx"
      subject.encoding = "UTF-8"
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:format]).to have(1).items
    end
  end

  describe "mass assignment with format" do
    it "does not raise UnknownAttributeError" do
      expect { subject.attributes = { "encoding" => "UTF-8", "format" => "csv" } }.not_to raise_error
      expect(subject.encoding).to eq "UTF-8"
      expect(subject.format).to eq "csv"
    end
  end
end
