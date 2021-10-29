require 'spec_helper'

RSpec.describe SS::FilePublisher::ByCopy, type: :model, dbscope: :example do
  subject { described_class.new }
  let(:file) { tmp_ss_file(contents: '0123456789', name: "#{ss_japanese_text}.txt", filename: "text.txt") }
  let(:dirname) { "#{tmpdir}/#{unique_id}" }

  describe "#publish" do
    before do
      subject.publish(file, dirname)
    end

    it do
      expect(::Dir.exists?(dirname)).to be_truthy

      expect(::File.exist?("#{dirname}/#{file.filename}")).to be_truthy
      expect(::File.symlink?("#{dirname}/#{file.filename}")).to be_falsey
      expect(::FileUtils.compare_file("#{dirname}/#{file.filename}", file.path)).to be_truthy

      expect(::File.exist?("#{dirname}/#{file.name}")).to be_truthy
      expect(::File.symlink?("#{dirname}/#{file.name}")).to be_falsey
      expect(::FileUtils.compare_file("#{dirname}/#{file.name}", file.path)).to be_truthy
    end
  end

  describe "#depublish" do
    before do
      subject.publish(file, dirname)
    end

    it do
      expect(::Dir.exists?(dirname)).to be_truthy

      subject.depublish(file, dirname)

      expect(::Dir.exists?(dirname)).to be_falsey
    end
  end
end
