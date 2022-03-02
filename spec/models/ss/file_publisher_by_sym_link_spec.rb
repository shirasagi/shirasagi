require 'spec_helper'

RSpec.describe SS::FilePublisher::BySymLink, type: :model, dbscope: :example do
  subject { described_class.new }
  let(:file) { tmp_ss_file(contents: '0123456789', name: "#{ss_japanese_text}.txt", filename: "text.txt") }
  let(:dirname) { "#{tmpdir}/#{unique_id}" }

  describe "#publish" do
    before do
      subject.publish(file, dirname)
    end

    it do
      expect(::Dir.exist?(dirname)).to be_truthy

      expect(::File.exist?("#{dirname}/#{file.filename}")).to be_truthy
      expect(::File.symlink?("#{dirname}/#{file.filename}")).to be_truthy
      expect(::File.readlink("#{dirname}/#{file.filename}")).to eq file.path

      expect(::File.exist?("#{dirname}/#{file.name}")).to be_truthy
      expect(::File.symlink?("#{dirname}/#{file.name}")).to be_truthy
      expect(::File.readlink("#{dirname}/#{file.name}")).to eq file.path
    end
  end

  describe "#depublish" do
    before do
      subject.publish(file, dirname)
    end

    it do
      expect(::Dir.exist?(dirname)).to be_truthy

      subject.depublish(file, dirname)

      expect(::Dir.exist?(dirname)).to be_falsey
    end
  end
end
