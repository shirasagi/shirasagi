require 'spec_helper'

describe Fs::UploadedFile do
  describe ".create_from_file" do
    context "when string path is given" do
      subject { described_class.create_from_file("#{Rails.root}/spec/fixtures/ss/logo.png", basename: "spec") }
      it { is_expected.not_to be_nil }
    end

    context "when File is given" do
      subject { described_class.create_from_file(File.open("#{Rails.root}/spec/fixtures/ss/logo.png"), basename: "spec") }
      it { is_expected.not_to be_nil }
    end

    context "when Pathname is given" do
      subject { described_class.create_from_file(Rails.root.join("spec/fixtures/ss/logo.png"), basename: "spec") }
      it { is_expected.not_to be_nil }
    end
  end
end
