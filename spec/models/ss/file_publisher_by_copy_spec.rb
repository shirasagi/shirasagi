require 'spec_helper'

RSpec.describe SS::FilePublisher::ByCopy, type: :model, dbscope: :example do
  subject { described_class.new }

  context "with .txt" do
    let(:basename) { unique_id }
    let(:basename_ja) { ss_japanese_text }
    let(:file) { tmp_ss_file(contents: '0123456789', name: "#{basename_ja}.txt", filename: "#{basename}.txt") }
    let(:dirname) { "#{tmpdir}/#{unique_id}" }

    describe "#publish" do
      before do
        subject.publish(file, dirname)
      end

      it do
        expect(::Dir.exist?(dirname)).to be_truthy

        expect(::File.exist?("#{dirname}/#{basename}.txt")).to be_truthy
        expect(::File.symlink?("#{dirname}/#{basename}.txt")).to be_falsey
        expect(::FileUtils.compare_file("#{dirname}/#{basename}.txt", file.path)).to be_truthy

        expect(::File.exist?("#{dirname}/#{basename_ja}.txt")).to be_truthy
        expect(::File.symlink?("#{dirname}/#{basename_ja}.txt")).to be_falsey
        expect(::FileUtils.compare_file("#{dirname}/#{basename_ja}.txt", file.path)).to be_truthy

        expect(::File.exist?("#{dirname}/#{basename}_thumb.txt")).to be_falsey
        expect(::File.symlink?("#{dirname}/#{basename}_thumb.txt")).to be_falsey
        # expect(::FileUtils.compare_file("#{dirname}/#{basename}_thumb.txt", file.thumb.path)).to be_truthy

        expect(::File.exist?("#{dirname}/#{basename_ja}_thumb.txt")).to be_falsey
        expect(::File.symlink?("#{dirname}/#{basename_ja}_thumb.txt")).to be_falsey
        # expect(::FileUtils.compare_file("#{dirname}/#{basename_ja}_thumb.txt", file.thumb.path)).to be_truthy
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

  context "with .png" do
    let(:path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
    let(:basename) { unique_id }
    let(:basename_ja) { ss_japanese_text }
    let(:file) do
      tmp_ss_file(contents: path, name: "#{basename_ja}.png", filename: "#{basename}.png")
    end
    let(:dirname) { "#{tmpdir}/#{unique_id}" }

    describe "#publish" do
      before do
        subject.publish(file, dirname)
      end

      it do
        expect(::Dir.exist?(dirname)).to be_truthy

        expect(::File.exist?("#{dirname}/#{basename}.png")).to be_truthy
        expect(::File.symlink?("#{dirname}/#{basename}.png")).to be_falsey
        expect(::FileUtils.compare_file("#{dirname}/#{basename}.png", file.path)).to be_truthy

        expect(::File.exist?("#{dirname}/#{basename_ja}.png")).to be_truthy
        expect(::File.symlink?("#{dirname}/#{basename_ja}.png")).to be_falsey
        expect(::FileUtils.compare_file("#{dirname}/#{basename_ja}.png", file.path)).to be_truthy

        expect(::File.exist?("#{dirname}/#{basename}_thumb.png")).to be_truthy
        expect(::File.symlink?("#{dirname}/#{basename}_thumb.png")).to be_falsey
        expect(::FileUtils.compare_file("#{dirname}/#{basename}_thumb.png", file.thumb.path)).to be_truthy

        expect(::File.exist?("#{dirname}/#{basename_ja}_thumb.png")).to be_truthy
        expect(::File.symlink?("#{dirname}/#{basename_ja}_thumb.png")).to be_falsey
        expect(::FileUtils.compare_file("#{dirname}/#{basename_ja}_thumb.png", file.thumb.path)).to be_truthy
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
end
