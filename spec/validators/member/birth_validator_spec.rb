require 'spec_helper'

describe Member::BirthValidator, type: :validator do
  subject { build :cms_member, in_birth: value }

  context 'valid date' do
    let(:value) { { era: "seireki", year: "2000", month: "1", day: "1" } }
    it do
      is_expected.to be_valid
    end

    let(:value) { { era: "meiji", year: "44", month: "2", day: "2" } }
    it do
      is_expected.to be_valid
    end

    let(:value) { { era: "taisho", year: "14", month: "3", day: "3" } }
    it do
      is_expected.to be_valid
    end

    let(:value) { { era: "showa", year: "63", month: "4", day: "4" } }
    it do
      is_expected.to be_valid
    end

    let(:value) { { era: "heisei", year: "30", month: "5", day: "5" } }
    it do
      is_expected.to be_valid
    end

    let(:value) { { era: "reiwa", year: "2", month: "6", day: "6" } }
    it do
      is_expected.to be_valid
    end
  end

  context 'invalid date' do
    context 'with blank' do
      let(:value) { { era: "seireki" } }
      it do
        is_expected.to be_invalid
      end

      let(:value) { { era: "seireki", year: "", month: "", day: "" } }
      it do
        is_expected.to be_invalid
      end

      let(:value) { { era: "seireki", year: "2000", month: "", day: "" } }
      it do
        is_expected.to be_invalid
      end

      let(:value) { { era: "seireki", year: "2000", month: "1", day: "" } }
      it do
        is_expected.to be_invalid
      end
    end

    context 'with Date ArgumentError' do
      let(:value) { { era: "seireki", year: "2000", month: "2", day: "31" } }
      it do
        is_expected.to be_invalid
      end

      let(:value) { { era: "seireki", year: "2000", month: "4", day: "31" } }
      it do
        is_expected.to be_invalid
      end
    end

    context 'with out of era' do
      let(:value) { { era: "seireki", year: "0", month: "0", day: "0" } }
      it do
        is_expected.to be_invalid
      end

      let(:value) { { era: "meiji", year: "45", month: "2", day: "2" } }
      it do
        is_expected.to be_invalid
      end

      let(:value) { { era: "taisho", year: "15", month: "3", day: "3" } }
      it do
        is_expected.to be_invalid
      end

      let(:value) { { era: "showa", year: "64", month: "4", day: "4" } }
      it do
        is_expected.to be_invalid
      end

      let(:value) { { era: "heisei", year: "31", month: "5", day: "5" } }
      it do
        is_expected.to be_invalid
      end
    end
  end
end
