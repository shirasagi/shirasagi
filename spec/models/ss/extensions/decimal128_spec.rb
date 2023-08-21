require 'spec_helper'

describe SS::Extensions::Decimal128 do
  let(:zero) { described_class.new("0.0") }
  let(:one) { described_class.new("1.0") }
  let(:minus_one) { described_class.new("-1.0") }

  describe "#add" do
    it { expect(one.add(zero, 0)).to eq one }
    it { expect(one.add(Integer(0), 0)).to eq one }
    it { expect(one.add(Float(0), 0)).to eq one }
  end

  describe "#sub" do
    it { expect(one.sub(zero, 0)).to eq one }
    it { expect(one.sub(Integer(0), 0)).to eq one }
    it { expect(one.sub(Float(0), 0)).to eq one }
  end

  describe "#div" do
    it { expect(one.div(described_class.new("1.0"), 0)).to eq one }
    it { expect(one.div(Integer(1), 0)).to eq one }
    it { expect(one.div(Float(1), 0)).to eq one }
  end

  describe "#mult" do
    it { expect(one.mult(described_class.new("1.0"), 0)).to eq one }
    it { expect(one.mult(Integer(1), 0)).to eq one }
    it { expect(one.mult(Float(1), 0)).to eq one }
  end

  describe "#+" do
    it { expect(zero + one).to eq one }
    it { expect(one + minus_one).to eq zero }
    it { expect(one + Integer(1)).to eq described_class.new("2.0") }
    it { expect(Integer(1) + one).to eq described_class.new("2.0") }
    it { expect(one + Float(1)).to eq described_class.new("2.0") }
    it { expect(Float(1) + one).to eq described_class.new("2.0") }
  end

  describe "#-" do
    it { expect(one - zero).to eq one }
    it { expect(zero - one).to eq minus_one }
    it { expect(one - Integer(1)).to eq zero }
    it { expect(Integer(1) - one).to eq zero }
    it { expect(one - Float(1)).to eq zero }
    it { expect(Float(1) - one).to eq zero }
  end

  describe "#+@" do
    it { expect(+ zero).to eq zero }
    it { expect(+ one).to eq one }
    it { expect(+ minus_one).to eq minus_one }
  end

  describe "#-@" do
    it { expect(- zero).to eq zero }
    it { expect(- one).to eq minus_one }
    it { expect(- minus_one).to eq one }
  end

  describe "#*" do
    it { expect(one * described_class.new("1.0")).to eq one }
    it { expect(minus_one * described_class.new("-1.0")).to eq one }
    it { expect(one * Integer(1)).to eq one }
    it { expect(Integer(1) * one).to eq one }
    it { expect(one * Float(1)).to eq one }
    it { expect(Float(1) * one).to eq one }
  end

  describe "#/" do
    it { expect(one / described_class.new("1.0")).to eq one }
    it { expect(minus_one / described_class.new("-1.0")).to eq one }
    it { expect(one / Integer(1)).to eq one }
    it { expect(Integer(1) / one).to eq one }
    it { expect(one / Float(1)).to eq one }
    it { expect(Float(1) / one).to eq one }
  end

  describe "#quo" do
    it { expect(one.quo(described_class.new("1.0"))).to eq one }
    it { expect(minus_one.quo(described_class.new("-1.0"))).to eq one }
    it { expect(one.quo(Integer(1))).to eq one }
    it { expect(Integer(1).quo(one)).to eq one }
    it { expect(one.quo(Float(1))).to eq one }
    it { expect(Float(1).quo(one)).to eq one }
  end

  describe "#abs" do
    it { expect(zero.abs).to eq zero }
    it { expect(one.abs).to eq one }
    it { expect(minus_one.abs).to eq one }
  end

  describe "#sqrt" do
    it { expect(one.sqrt(Integer(2))).to eq one }
    it { expect(one.sqrt(Float(2))).to eq one }
    it { expect(one.sqrt(described_class.new("2.0"))).to eq one }
    it { expect { minus_one.sqrt(2) }.to raise_error FloatDomainError }
  end

  describe "#fix" do
    it { expect(zero.fix).to eq zero }
    it { expect(one.fix).to eq one }
    it { expect(minus_one.fix).to eq minus_one }
  end

  describe "#round" do
    it { expect(one.round).to eq one }
    it { expect(one.round).to be_a(Integer) }
    it { expect(one.round(1)).to eq one }
    it { expect(one.round(1)).to be_a(described_class) }
    it { expect(one.round(1, 1)).to eq one }
    it { expect(one.round(1, 1)).to be_a(described_class) }
  end

  describe "#frac" do
    it { expect(zero.frac).to eq zero }
    it { expect(one.frac).to eq zero }
    it { expect(minus_one.frac).to eq zero }
  end

  describe "#power" do
    it { expect(one.power(1)).to eq one }
    it { expect(one.power(1)).to be_a(described_class) }
    it { expect(one.power(1, 1)).to eq one }
    it { expect(one.power(1, 1)).to be_a(described_class) }
  end

  describe "#**" do
    it { expect(one ** Integer(1)).to eq one }
    it { expect(one ** Float(1.0)).to eq one }
    it { expect(one ** BigDecimal("1.0")).to eq one }
    it { expect(one ** described_class.new("1.0")).to eq one }
  end

  describe "#<=>" do
    it { expect(one <=> described_class.new("1.0")).to eq 0 }
    it { expect(minus_one <=> described_class.new("-1.0")).to eq 0 }
    it { expect(one <=> zero).to be > 0 }
    it { expect(zero <=> one).to be < 0 }
    it { expect(zero <=> Integer(1)).to be < 0 }
    it { expect(Integer(1) <=> zero).to be > 0 }
    it { expect(zero <=> Float(1)).to be < 0 }
    it { expect(Float(1) <=> zero).to be > 0 }
  end

  describe "#eql?" do
    it { expect(one.eql?(described_class.new("1.0"))).to be_truthy }
    it { expect(minus_one.eql?(described_class.new("-1.0"))).to be_truthy }
    it { expect(one.eql?(zero)).to be_falsey }
    it { expect(zero.eql?(one)).to be_falsey }
  end

  describe "#==" do
    it { expect(one == described_class.new("1.0")).to be_truthy }
    it { expect(minus_one == described_class.new("-1.0")).to be_truthy }
    it { expect(one == zero).to be_falsey }
    it { expect(zero == one).to be_falsey }
  end

  describe "#fdiv" do
    it { expect(one.fdiv(one)).to eq 1.0 }
    it { expect(one.fdiv(one)).to be_a(described_class) }
  end

  describe "#divmod" do
    it { expect(one.divmod(one)).to eq [ one, zero ] }
  end

  describe "#%" do
    it { expect(described_class.new("-3.0") % described_class.new("2")).to eq one }
    it { expect(described_class.new("-3.0") % Integer(2)).to eq one }
    it { expect(described_class.new("-3.0") % Float(2.0)).to eq one }
    it { expect(described_class.new("-3.0") % BigDecimal("2.0")).to eq one }
  end

  describe "#modulo" do
    it { expect(described_class.new("-3.0").modulo(described_class.new("2"))).to eq one }
    it { expect(described_class.new("-3.0").modulo(Integer(2))).to eq one }
    it { expect(described_class.new("-3.0").modulo(Float(2.0))).to eq one }
    it { expect(described_class.new("-3.0").modulo(BigDecimal("2.0"))).to eq one }
  end

  describe "#remainder" do
    it { expect(described_class.new("-3.0").remainder(described_class.new("2"))).to eq minus_one }
    it { expect(described_class.new("-3.0").remainder(Integer(2))).to eq minus_one }
    it { expect(described_class.new("-3.0").remainder(Float(2.0))).to eq minus_one }
    it { expect(described_class.new("-3.0").remainder(BigDecimal("2.0"))).to eq minus_one }
  end

  describe "#magnitude" do
    it { expect(zero.magnitude).to eq zero }
    it { expect(one.magnitude).to eq one }
    it { expect(minus_one.magnitude).to eq one }
  end

  describe "#===" do
    it { expect(one === described_class.new("1.0")).to be_truthy }
    it { expect(minus_one === described_class.new("-1.0")).to be_truthy }
    it { expect(one === zero).to be_falsey }
    it { expect(zero === one).to be_falsey }
  end

  describe "#>" do
    it { expect(zero < one).to be_truthy }
    it { expect(one < zero).to be_falsey }
  end

  describe "#>=" do
    it { expect(zero <= one).to be_truthy }
    it { expect(one <= zero).to be_falsey }
  end

  describe "#<" do
    it { expect(zero < one).to be_truthy }
    it { expect(one < zero).to be_falsey }
  end

  describe "#<=" do
    it { expect(zero <= one).to be_truthy }
    it { expect(one <= zero).to be_falsey }
  end

  describe "#between?" do
    it { expect(zero.between?(minus_one, one)).to be_truthy }
    it { expect(described_class.new("2.0").between?(minus_one, one)).to be_falsey }
  end

  describe "#clamp" do
    it { expect(zero.clamp(minus_one, one)).to eq zero }
    it { expect(described_class.new("2.0").clamp(minus_one, one)).to eq one }
    it { expect(described_class.new("-2.0").clamp(minus_one, one)).to eq minus_one }
  end
end
