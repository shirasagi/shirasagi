require 'spec_helper'

describe SS::FilenameUtils, dbscope: :example do
  describe ".normalize" do
    context "with nfkc" do
      before do
        @save = SS.config.env.unicode_normalization_method
        SS.config.replace_value_at(:env, :unicode_normalization_method, :nfkc)
      end

      after do
        SS.config.replace_value_at(:env, :unicode_normalization_method, @save)
      end

      it do
        expect(SS::FilenameUtils.normalize(nil)).to be_nil
        expect(SS::FilenameUtils.normalize("a.pdf")).to eq "a.pdf"
        # nfd
        expect(SS::FilenameUtils.normalize("プロ.txt")).to eq "プロ.txt"
        expect(SS::FilenameUtils.normalize("フ\u309Aロ.txt")).to eq "プロ.txt"
        # nfkd
        expect(SS::FilenameUtils.normalize("ﬁ.txt")).to eq "fi.txt"
        expect(SS::FilenameUtils.normalize("①.txt")).to eq "1.txt"
        expect(SS::FilenameUtils.normalize("㍻.txt")).to eq "平成.txt"
      end
    end

    context "with nfc" do
      before do
        @save = SS.config.env.unicode_normalization_method
        SS.config.replace_value_at(:env, :unicode_normalization_method, :nfc)
      end

      after do
        SS.config.replace_value_at(:env, :unicode_normalization_method, @save)
      end

      it do
        expect(SS::FilenameUtils.normalize(nil)).to be_nil
        expect(SS::FilenameUtils.normalize("a.pdf")).to eq "a.pdf"
        # nfd
        expect(SS::FilenameUtils.normalize("プロ.txt")).to eq "プロ.txt"
        expect(SS::FilenameUtils.normalize("フ\u309Aロ.txt")).to eq "プロ.txt"
        # nfkd
        expect(SS::FilenameUtils.normalize("ﬁ.txt")).to eq "ﬁ.txt"
        expect(SS::FilenameUtils.normalize("①.txt")).to eq "①.txt"
        expect(SS::FilenameUtils.normalize("㍻.txt")).to eq "㍻.txt"
      end
    end
  end

  describe ".url_safe_japanese?" do
    context "when nil is given" do
      it do
        expect { SS::FilenameUtils.url_safe_japanese?(nil) }.to raise_error NoMethodError
      end
    end

    context "when empty string is given" do
      it do
        expect(SS::FilenameUtils.url_safe_japanese?("")).to be_truthy
      end
    end

    context "when half width chars are given" do
      it do
        expect(SS::FilenameUtils.url_safe_japanese?("0")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("9")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("A")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("Z")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("a")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("z")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("`")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("~")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("@")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("#")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("$")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("%")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("^")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("&")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("*")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("(")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?(")")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("-")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("_")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("=")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("+")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("[")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("]")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("{")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("}")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("\\")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("|")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?(":")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?(";")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("'")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("\"")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?(",")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?(".")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("<")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?(">")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("?")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("/")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?(" ")).to be_truthy
      end
    end

    context "when sjis full width symbols are given" do
      it do
        expect(SS::FilenameUtils.url_safe_japanese?("「")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("【")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("『")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("（")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("＜")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("＿")).to be_truthy
      end
    end

    context "when hiragana chars are given" do
      it do
        expect(SS::FilenameUtils.url_safe_japanese?("ぁ")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("あ")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("ん")).to be_truthy
      end
    end

    context "when katakana chars are given" do
      it do
        expect(SS::FilenameUtils.url_safe_japanese?("ァ")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("ア")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("ヶ")).to be_truthy
      end
    end

    context "when jis 1st level kanji chars are given" do
      it do
        expect(SS::FilenameUtils.url_safe_japanese?("亜")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("腕")).to be_truthy
      end
    end

    context "when jis 2nd level kanji chars are given" do
      it do
        expect(SS::FilenameUtils.url_safe_japanese?("弌")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("熙")).to be_truthy
      end
    end

    context "when sjis vendor specific symbols are given" do
      it do
        expect(SS::FilenameUtils.url_safe_japanese?("①")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("㌍")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("㊤")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("㍼")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("≒")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("∑")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("㊤")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("ⅲ")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("Ⅳ")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("￢")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("￤")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("＇")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("＂")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("㈱")).to be_truthy
      end
    end

    context "when sjis vendor specific kanji chars are given" do
      it do
        expect(SS::FilenameUtils.url_safe_japanese?("纊")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("煆")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("纊")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("僴")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("琦")).to be_truthy
        expect(SS::FilenameUtils.url_safe_japanese?("黑")).to be_truthy
      end
    end

    context "when non-sjis chars are given" do
      it do
        expect(SS::FilenameUtils.url_safe_japanese?("š")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("圳")).to be_falsey
        expect(SS::FilenameUtils.url_safe_japanese?("😀")).to be_falsey
      end
    end
  end

  describe ".convert_to_url_safe_japanese" do
    before do
      @save = SS.config.env.unicode_normalization_method
      SS.config.replace_value_at(:env, :unicode_normalization_method, :nfkc)
    end

    after do
      SS.config.replace_value_at(:env, :unicode_normalization_method, @save)
    end

    context "when nil is given" do
      it do
        expect { described_class.convert_to_url_safe_japanese(nil) }.to raise_error NoMethodError
      end
    end

    context "when alhpanum filename samples are given" do
      it do
        expect(described_class.convert_to_url_safe_japanese("file_staging_1920.txt")).to eq "file_staging_1920.txt"
        expect(described_class.convert_to_url_safe_japanese("covid19-warnings.pdf")).to eq "covid19-warnings.pdf"
        expect(described_class.convert_to_url_safe_japanese("[tokyo2021] stadium list [welcome].xlsx")).to \
          eq "tokyo2021_stadium list welcome.xlsx"
        expect(described_class.convert_to_url_safe_japanese("+++aaaa++++bbbb++++.txt")).to eq "aaaa+bbbb.txt"
        expect(described_class.convert_to_url_safe_japanese("file.$$")).to eq "file.$"
        expect(described_class.convert_to_url_safe_japanese("file (2).txt")).to eq "file (2).txt"
        # nbsp (\u00a0)
        expect(described_class.convert_to_url_safe_japanese("aaa\u00a0bbbb.pdf")).to eq "aaa bbbb.pdf"
        # control chars
        expect(described_class.convert_to_url_safe_japanese("aaa\tbbbb.pdf")).to eq "aaa_bbbb.pdf"
        expect(described_class.convert_to_url_safe_japanese("aaa\rbbbb.pdf")).to eq "aaa_bbbb.pdf"
        expect(described_class.convert_to_url_safe_japanese("aaa\nbbbb.pdf")).to eq "aaa_bbbb.pdf"
        expect(described_class.convert_to_url_safe_japanese("aaa#{(0x00..0x1f).to_a.sample.chr}bbbb.pdf")).to eq "aaa_bbbb.pdf"
        expect(described_class.convert_to_url_safe_japanese("aaa#{0x7f.chr}bbbb.pdf")).to eq "aaa_bbbb.pdf"
      end
    end

    context "when filesystem unsafe chars on windows 7 or later are given" do
      it do
        expect(described_class.convert_to_url_safe_japanese("file\\after.txt")).to eq "file_after.txt"
        expect(described_class.convert_to_url_safe_japanese("file/after.txt")).to eq "file_after.txt"
        expect(described_class.convert_to_url_safe_japanese("file:after.txt")).to eq "file_after.txt"
        expect(described_class.convert_to_url_safe_japanese("file*after.txt")).to eq "file_after.txt"
        expect(described_class.convert_to_url_safe_japanese("file?after.txt")).to eq "file_after.txt"
        expect(described_class.convert_to_url_safe_japanese("file\"after.txt")).to eq "file_after.txt"
        expect(described_class.convert_to_url_safe_japanese("file<after.txt")).to eq "file_after.txt"
        expect(described_class.convert_to_url_safe_japanese("file>after.txt")).to eq "file_after.txt"
        expect(described_class.convert_to_url_safe_japanese("file|after.txt")).to eq "file_after.txt"
      end
    end

    context "when japanese filename samples are given" do
      it do
        expect(described_class.convert_to_url_safe_japanese("テスト😀.txt")).to eq "テスト＿.txt"
        expect(described_class.convert_to_url_safe_japanese("ファイル①.pdf")).to eq "ファイル1.pdf"
        expect(described_class.convert_to_url_safe_japanese("（本番）サービスⅲ.docx")).to eq "(本番)サービスiii.docx"
        expect(described_class.convert_to_url_safe_japanese("深圳")).to eq "深＿"
        expect(described_class.convert_to_url_safe_japanese("_____.pdf")).to eq "_.pdf"
        expect(described_class.convert_to_url_safe_japanese("ポスター/表.pdf")).to eq "ポスター_表.pdf"
        expect(described_class.convert_to_url_safe_japanese("調査結果.docx - コピー")).to eq "調査結果.docx コピー"
        expect(described_class.convert_to_url_safe_japanese("2016年1月1日～2016年1月2日.zip")).to eq "2016年1月1日~2016年1月2日.zip"
      end
    end

    context "when nfd is given" do
      it do
        # nfd
        expect(described_class.convert_to_url_safe_japanese("フ\u309Aロ.txt")).to eq "プロ.txt"
      end
    end
  end
end
