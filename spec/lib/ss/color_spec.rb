require 'spec_helper'

describe SS::Color do
  describe ".parse" do
    context "with valid colors" do
      it do
        # 6-digit starting with '#'
        SS::Color.parse("#000000").tap do |rgb|
          expect(rgb.red).to eq 0
          expect(rgb.green).to eq 0
          expect(rgb.blue).to eq 0
        end
        SS::Color.parse("#ffffff").tap do |rgb|
          expect(rgb.red).to eq 255
          expect(rgb.green).to eq 255
          expect(rgb.blue).to eq 255
        end
        SS::Color.parse("#ffffff".upcase).tap do |rgb|
          expect(rgb.red).to eq 255
          expect(rgb.green).to eq 255
          expect(rgb.blue).to eq 255
        end

        # 3-digits starting with '#'
        SS::Color.parse("#000").tap do |rgb|
          expect(rgb.red).to eq 0
          expect(rgb.green).to eq 0
          expect(rgb.blue).to eq 0
        end
        SS::Color.parse("#fff").tap do |rgb|
          expect(rgb.red).to eq 255
          expect(rgb.green).to eq 255
          expect(rgb.blue).to eq 255
        end
        SS::Color.parse("#fff".upcase).tap do |rgb|
          expect(rgb.red).to eq 255
          expect(rgb.green).to eq 255
          expect(rgb.blue).to eq 255
        end

        # just 6-digit
        SS::Color.parse("000000").tap do |rgb|
          expect(rgb.red).to eq 0
          expect(rgb.green).to eq 0
          expect(rgb.blue).to eq 0
        end
        SS::Color.parse("ffffff").tap do |rgb|
          expect(rgb.red).to eq 255
          expect(rgb.green).to eq 255
          expect(rgb.blue).to eq 255
        end
        SS::Color.parse("ffffff".upcase).tap do |rgb|
          expect(rgb.red).to eq 255
          expect(rgb.green).to eq 255
          expect(rgb.blue).to eq 255
        end

        # just 3-digits
        SS::Color.parse("000").tap do |rgb|
          expect(rgb.red).to eq 0
          expect(rgb.green).to eq 0
          expect(rgb.blue).to eq 0
        end
        SS::Color.parse("fff").tap do |rgb|
          expect(rgb.red).to eq 255
          expect(rgb.green).to eq 255
          expect(rgb.blue).to eq 255
        end
        SS::Color.parse("fff".upcase).tap do |rgb|
          expect(rgb.red).to eq 255
          expect(rgb.green).to eq 255
          expect(rgb.blue).to eq 255
        end
      end
    end

    context "with invalid colors" do
      it do
        expect(SS::Color.parse(nil)).to be_nil
        expect(SS::Color.parse("")).to be_nil
        expect(SS::Color.parse("z")).to be_nil
        expect(SS::Color.parse("zz")).to be_nil
        expect(SS::Color.parse("zzz")).to be_nil
        expect(SS::Color.parse("zzzz")).to be_nil
        expect(SS::Color.parse("zzzzz")).to be_nil
        expect(SS::Color.parse("zzzzzz")).to be_nil
      end
    end
  end
end
