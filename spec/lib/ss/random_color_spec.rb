require 'spec_helper'

describe SS::RandomColor do
  describe ".next" do
    it do
      gen = SS::RandomColor.new(0)
      expect(gen.next.to_s).to eq "hsl(12,89%,40%)"
      expect(gen.next.to_s).to eq "hsl(99,45%,79%)"
      expect(gen.next.to_s).to eq "hsl(201,61%,61%)"
    end
  end

  describe ".to_rgb" do
    it do
      gen = SS::RandomColor.new(85_523)
      expect(gen.next.to_rgb.to_s).to eq "#d5784d"
      expect(gen.next.to_rgb.to_s).to eq "#75ce63"
      expect(gen.next.to_rgb.to_s).to eq "#b2ccdf"
    end
  end
end

describe SS::RandomColor::Hsl do
  describe ".to_rgb" do
    context "hue is between 0 and 60" do
      subject { SS::RandomColor::Hsl.new(25, 80, 25) }

      it do
        expect(subject.to_rgb.to_s).to eq "#72370c"
      end
    end

    context "hue is between 60 and 120" do
      subject { SS::RandomColor::Hsl.new(85, 80, 25) }

      it do
        expect(subject.to_rgb.to_s).to eq "#48720c"
      end
    end

    context "hue is between 120 and 180" do
      subject { SS::RandomColor::Hsl.new(145, 80, 25) }

      it do
        expect(subject.to_rgb.to_s).to eq "#0c7237"
      end
    end

    context "hue is between 180 and 240" do
      subject { SS::RandomColor::Hsl.new(205, 80, 25) }

      it do
        expect(subject.to_rgb.to_s).to eq "#0c4872"
      end
    end

    context "hue is between 240 and 300" do
      subject { SS::RandomColor::Hsl.new(265, 80, 25) }

      it do
        expect(subject.to_rgb.to_s).to eq "#370c72"
      end
    end

    context "hue is between 300 and 360" do
      subject { SS::RandomColor::Hsl.new(325, 80, 25) }

      it do
        expect(subject.to_rgb.to_s).to eq "#720c48"
      end
    end
  end
end
