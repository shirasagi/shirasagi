require 'spec_helper'

describe SS::Csv do
  context "csv as path is given" do
    let(:path) { "#{Rails.root}/spec/fixtures/article/article_import_test_1.csv" }

    it do
      expect(described_class.detect_encoding(path)).to eq Encoding::SJIS
    end
  end

  context "json as io is given" do
    let(:path) { "#{Rails.root}/spec/fixtures/ckan/package_search.json" }

    it do
      ::File.open(path, "rb") do |f|
        expect(described_class.detect_encoding(f)).to eq Encoding::UTF_8
      end
    end
  end

  context "zip as ss/file is given" do
    let(:file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/cms/import/site.zip") }

    it do
      expect(described_class.detect_encoding(file)).to eq Encoding::ASCII_8BIT
    end
  end

  context "pdf is given" do
    let(:path) { "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf" }

    it do
      expect(described_class.detect_encoding(path)).to eq Encoding::ASCII_8BIT
    end
  end

  context "xlsx is given" do
    let(:path) { "#{Rails.root}/spec/fixtures/opendata/map_resources/sample1.xlsx" }

    it do
      expect(described_class.detect_encoding(path)).to eq Encoding::ASCII_8BIT
    end
  end

  context "png is given" do
    let(:path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

    it do
      expect(described_class.detect_encoding(path)).to eq Encoding::ASCII_8BIT
    end
  end

  context "jpg is given" do
    let(:path) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg" }

    it do
      expect(described_class.detect_encoding(path)).to eq Encoding::ASCII_8BIT
    end
  end

  context "gif is given" do
    let(:path) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif" }

    it do
      expect(described_class.detect_encoding(path)).to eq Encoding::ASCII_8BIT
    end
  end

  context "UTF-8 (without BOM) csv is given" do
    let(:path) { "#{Rails.root}/spec/fixtures/opendata/utf-8.csv" }

    it do
      expect(described_class.detect_encoding(path)).to eq Encoding::UTF_8
    end
  end

  context "UTF-8 (with BOM) csv is given" do
    let(:path) { "#{Rails.root}/spec/fixtures/ss/replace_file/after_csv.csv" }

    it do
      expect(described_class.detect_encoding(path)).to eq Encoding::UTF_8
    end
  end

  context "random UTF-8 is given" do
    let(:path) do
      # 末端が不利な位置にあっても正しく文字コードを判定できることを確認するためのデータ
      # さまざまな乱数シードを用いて 10 連続で成功することを確認済み
      tmpfile do |file|
        file.write "a" * rand(1..3)
        file.write ss_japanese_text while file.size < 1024
      end
    end

    it do
      expect(described_class.detect_encoding(path)).to eq Encoding::UTF_8
    end
  end

  context "random SJIS is given" do
    let(:path) do
      # 末端が不利な位置にあっても正しく文字コードを判定できることを確認するためのデータ
      # さまざまな乱数シードを用いて 10 連続で成功することを確認済み
      tmpfile(binary: true) do |file|
        file.write "a" * rand(1..3)
        file.write "シラサギ".encode("SJIS") while file.size < 1024
      end
    end

    it do
      expect(described_class.detect_encoding(path)).to eq Encoding::SJIS
    end
  end
end
