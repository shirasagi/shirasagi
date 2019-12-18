require 'spec_helper'

describe Sys::PrefectureCode, dbscope: :example do
  describe ".check_digit" do
    it do
      expect(described_class.check_digit("00000")).to eq "1"
      expect(described_class.check_digit("99999")).to eq "7"
    end

    it do
      expect(described_class.check_digit("01000")).to eq "6"
      expect(described_class.check_digit("01100")).to eq "2"
      expect(described_class.check_digit("43104")).to eq "4"
      expect(described_class.check_digit("43105")).to eq "2"
    end
  end

  describe ".search" do
    let!(:item) { create :sys_prefecture_code }
    let!(:item_alternative) { create :sys_prefecture_code }

    context "with keyword" do
      it do
        expect(described_class.search(keyword: unique_id).count).to eq 0
      end

      it do
        expect(described_class.search(keyword: item.code).count).to eq 1
        expect(described_class.search(keyword: item.code).first).to eq item
      end

      it do
        expect(described_class.search(keyword: item.prefecture).count).to eq 1
        expect(described_class.search(keyword: item.prefecture).first).to eq item
      end
    end

    context "with code" do
      it do
        expect(described_class.search(code: unique_id).count).to eq 0
      end

      it do
        expect(described_class.search(code: item.code).count).to eq 1
        expect(described_class.search(code: item.code).first).to eq item
      end

      it do
        # hyphenated postal code
        code = "#{item.code[0, 3]}-#{item.code[3, 4]}"
        expect(described_class.search(code: code).count).to eq 1
        expect(described_class.search(code: code).first).to eq item
      end

      it do
        # full-width postal code
        code = item.code.tr('0-9a-zA-Z', '０-９ａ-ｚＡ-Ｚ')
        expect(described_class.search(code: code).count).to eq 1
        expect(described_class.search(code: code).first).to eq item
      end
    end
  end
end
