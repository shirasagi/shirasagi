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
end
