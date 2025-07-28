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

  describe ".brightness" do
    context "with valid colors" do
      it do
        # 6-digit starting with '#'
        expect(SS::Color.brightness("#000000")).to be_within(0.01).of(0)
        expect(SS::Color.brightness("#ffffff")).to be_within(0.01).of(255)
        expect(SS::Color.brightness("#ffffff".upcase)).to be_within(0.01).of(255)

        # 3-digits starting with '#'
        expect(SS::Color.brightness("#000")).to be_within(0.01).of(0)
        expect(SS::Color.brightness("#fff")).to be_within(0.01).of(255)
        expect(SS::Color.brightness("#fff".upcase)).to be_within(0.01).of(255)

        # just 6-digit
        expect(SS::Color.brightness("000000")).to be_within(0.01).of(0)
        expect(SS::Color.brightness("ffffff")).to be_within(0.01).of(255)
        expect(SS::Color.brightness("ffffff".upcase)).to be_within(0.01).of(255)

        # just 3-digits
        expect(SS::Color.brightness("000")).to be_within(0.01).of(0)
        expect(SS::Color.brightness("fff")).to be_within(0.01).of(255)
        expect(SS::Color.brightness("fff".upcase)).to be_within(0.01).of(255)
      end
    end

    context "with invalid colors" do
      it do
        expect(SS::Color.brightness(nil)).to be_nil
        expect(SS::Color.brightness("")).to be_nil
        expect(SS::Color.brightness("z")).to be_nil
        expect(SS::Color.brightness("zz")).to be_nil
        expect(SS::Color.brightness("zzz")).to be_nil
        expect(SS::Color.brightness("zzzz")).to be_nil
        expect(SS::Color.brightness("zzzzz")).to be_nil
        expect(SS::Color.brightness("zzzzzz")).to be_nil
      end
    end
  end

  describe ".text_color" do
    context "with valid colors" do
      it do
        # 6-digit starting with '#'
        expect(SS::Color.text_color("#000000")).to eq "#ffffff"
        expect(SS::Color.text_color("#ffffff")).to eq "#000000"
        expect(SS::Color.text_color("#ffffff".upcase)).to eq "#000000"

        # 3-digits starting with '#'
        expect(SS::Color.text_color("#000")).to eq "#ffffff"
        expect(SS::Color.text_color("#fff")).to eq "#000000"
        expect(SS::Color.text_color("#fff".upcase)).to eq "#000000"

        # just 6-digit
        expect(SS::Color.text_color("000000")).to eq "#ffffff"
        expect(SS::Color.text_color("ffffff")).to eq "#000000"
        expect(SS::Color.text_color("ffffff".upcase)).to eq "#000000"

        # just 3-digits
        expect(SS::Color.text_color("000")).to eq "#ffffff"
        expect(SS::Color.text_color("fff")).to eq "#000000"
        expect(SS::Color.text_color("fff".upcase)).to eq "#000000"
      end
    end

    context "with invalid colors" do
      it do
        expect(SS::Color.text_color(nil)).to be_nil
        expect(SS::Color.text_color("")).to be_nil
        expect(SS::Color.text_color("z")).to be_nil
        expect(SS::Color.text_color("zz")).to be_nil
        expect(SS::Color.text_color("zzz")).to be_nil
        expect(SS::Color.text_color("zzzz")).to be_nil
        expect(SS::Color.text_color("zzzzz")).to be_nil
        expect(SS::Color.text_color("zzzzzz")).to be_nil
      end
    end
  end
end
