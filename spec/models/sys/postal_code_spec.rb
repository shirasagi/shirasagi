require 'spec_helper'

describe Sys::PostalCode, dbscope: :example do
  describe ".search" do
    let!(:item) { create :sys_postal_code }
    let!(:item_alternative) { create :sys_postal_code }

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
