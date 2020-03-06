require 'spec_helper'

describe SS::ColorContrast do
  describe ".from_css_color" do
    context "given specific color" do
      it do
        expect(SS::ColorContrast.from_css_color("#404040", "#a8a8a8")).to be_within(0.01).of(4.36)
        expect(SS::ColorContrast.from_css_color("#0000ff", "#ffffff")).to be_within(0.01).of(8.59)
        expect(SS::ColorContrast.from_css_color("#8a8aff", "#ffffff")).to be_within(0.01).of(2.93)
        expect(SS::ColorContrast.from_css_color("#fb2900", "#ffe325")).to be_within(0.01).of(3.0)
      end
    end

    context "given 3-hex-decimal color" do
      it do
        expect(SS::ColorContrast.from_css_color("#00f", "#fff")).to be_within(0.01).of(8.59)
      end
    end

    context "vise versa" do
      it do
        expect(SS::ColorContrast.from_css_color("#404040", "#a8a8a8")).to \
          eq SS::ColorContrast.from_css_color("#a8a8a8", "#404040")
        expect(SS::ColorContrast.from_css_color("#0000ff", "#ffffff")).to \
          eq SS::ColorContrast.from_css_color("#ffffff", "#0000ff")
        expect(SS::ColorContrast.from_css_color("#8a8aff", "#ffffff")).to \
          eq SS::ColorContrast.from_css_color("#ffffff", "#8a8aff")
        expect(SS::ColorContrast.from_css_color("#fb2900", "#ffe325")).to \
          eq SS::ColorContrast.from_css_color("#ffe325", "#fb2900")
        expect(SS::ColorContrast.from_css_color("#00f", "#fff")).to \
          eq SS::ColorContrast.from_css_color("#fff", "#00f")
      end
    end
  end
end
