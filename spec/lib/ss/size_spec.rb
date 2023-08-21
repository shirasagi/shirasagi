require 'spec_helper'

describe SS::Size do
  describe ".parse" do
    context "with valid sizes" do
      it do
        expect(SS::Size.parse("104857600")).to eq 104_857_600
        expect(SS::Size.parse("100k")).to eq 100 * 1024
        expect(SS::Size.parse("100K")).to eq 100 * 1024
        expect(SS::Size.parse("100m")).to eq 100 * 1024 * 1024
        expect(SS::Size.parse("100M")).to eq 100 * 1024 * 1024
        expect(SS::Size.parse("100g")).to eq 100 * 1024 * 1024 * 1024
        expect(SS::Size.parse("100G")).to eq 100 * 1024 * 1024 * 1024
        expect(SS::Size.parse("100t")).to eq 100 * 1024 * 1024 * 1024 * 1024
        expect(SS::Size.parse("100T")).to eq 100 * 1024 * 1024 * 1024 * 1024
      end
    end

    context "with invalid unit" do
      it do
        expect { SS::Size.parse("100p") }.to raise_error RuntimeError, "malformed size: 100p"
      end
    end

    context "with non-number" do
      it do
        expect { SS::Size.parse("hello") }.to raise_error RuntimeError, "malformed size: hello"
      end
    end

    context "with number" do
      it do
        expect(SS::Size.parse(104_857_600)).to eq 104_857_600
      end
    end
  end
end
