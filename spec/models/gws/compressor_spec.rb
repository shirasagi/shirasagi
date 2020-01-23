require 'spec_helper'

describe Gws::Compressor, type: :model, dbscope: :example do
  let(:user) { gws_user }
  let(:files) { SS::File.in(id: [ file1.id, file2.id ]).order_by(id: 1) }
  let(:filename) { "#{unique_id}.zip" }
  let(:compressor) do
    compressor = Gws::Compressor.new(user, items: files, filename: filename)
    compressor.url = "http://#{unique_id}.example.jp/"
    compressor
  end

  def extract_entry_names(path)
    ret = []

    Zip::File.open(path) do |zip_file|
      zip_file.each do |entry|
        ret << NKF.nkf("-w", entry.name)
      end
    end

    ret
  end

  context "with usual case" do
    let(:file1) { tmp_ss_file(contents: '0123456789', user: user, basename: "#{unique_id}.txt") }
    let(:file2) { tmp_ss_file(contents: '0123456789', user: user, basename: "#{unique_id}.txt") }

    it do
      expect(compressor.save).to be_truthy

      names = extract_entry_names(compressor.path)
      expect(names.length).to eq 2
      expect(names).to include(file1.name, file2.name)
    end
  end

  context "with 2 files with same name" do
    let(:file1) { tmp_ss_file(contents: '0123456789', user: user, basename: "text.txt") }
    let(:file2) { tmp_ss_file(contents: '0123456789', user: user, basename: "text.txt") }

    it do
      expect(file1.name).to eq file2.name

      expect(compressor.save).to be_truthy

      names = extract_entry_names(compressor.path)
      expect(names.length).to eq 2
      expect(names).to include("text.txt", "text_#{file2.id}.txt")
    end
  end

  context "with 2 files which name ends with period" do
    let(:file1) { tmp_ss_file(contents: '0123456789', user: user, basename: "text.") }
    let(:file2) { tmp_ss_file(contents: '0123456789', user: user, basename: "text.") }

    it do
      expect(file1.name).to eq file2.name

      expect(compressor.save).to be_truthy

      names = extract_entry_names(compressor.path)
      expect(names.length).to eq 2
      expect(names).to include("text", "text_#{file2.id}")
    end
  end

  context "with 2 files with same name and no ext" do
    let(:file1) { tmp_ss_file(contents: '0123456789', user: user, basename: "text") }
    let(:file2) { tmp_ss_file(contents: '0123456789', user: user, basename: "text") }

    it do
      expect(file1.name).to eq file2.name
      expect(file1.filename.include?(".")).to be_falsey

      expect(compressor.save).to be_truthy

      names = extract_entry_names(compressor.path)
      expect(names.length).to eq 2
      expect(names).to include("text", "text_#{file2.id}")
    end
  end
end
