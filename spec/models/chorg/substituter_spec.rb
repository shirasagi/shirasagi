require 'spec_helper'

describe Chorg::Substituter::IdSubstituter, dbscope: :example do
  let(:group) { cms_group }
  describe "#call" do
    context "with Integer" do
      let(:from) { 32_840 }
      let(:to) { 27_509 }
      subject { described_class.new(from, to) }
      it { expect(subject.call(:key, 32_840, group.id)).to eq 27_509 }
      it { expect(subject.call(:key, 53_643, group.id)).to eq 53_643 }
    end

    context "with Array" do
      let(:from) { 32_840 }
      let(:to) { 27_509 }
      subject { described_class.new(from, to) }
      it { expect(subject.call(:key, [32_840], group.id)).to eq [27_509] }
      it { expect(subject.call(:key, [53_643], group.id)).to eq [53_643] }
      it { expect(subject.call(:key, [32_840, 53_643, 2_105], group.id)).to eq [27_509, 53_643, 2_105] }
    end

    context "from Integer to Array" do
      let(:from) { 32_840 }
      let(:to) { [ 27_509, 62_033 ] }
      subject { described_class.new(from, to) }
      it { expect(subject.call(:key, 32_840, group.id)).to eq 27_509 }
      it { expect(subject.call(:key, 53_643, group.id)).to eq 53_643 }
      it { expect(subject.call(:key, [32_840], group.id)).to eq [27_509, 62_033] }
      it { expect(subject.call(:key, [53_643], group.id)).to eq [53_643] }
      it { expect(subject.call(:key, [32_840, 53_643], group.id)).to eq [27_509, 62_033, 53_643] }
    end
  end

  describe "#<=>" do
    context "normal situation" do
      let(:substituer1) { Chorg::Substituter::IdSubstituter.new(30_016, 27_509) }
      let(:substituer2) { Chorg::Substituter::IdSubstituter.new(44_103, 9_338) }
      let(:substituer3) { Chorg::Substituter::IdSubstituter.new(50_123, 10_636) }
      it { expect(substituer1).to be > substituer2 }
      it { expect(substituer1).to be > substituer3 }
      it { expect(substituer2).to be > substituer3 }
    end

    context "edge case" do
      let(:substituer1) { Chorg::Substituter::IdSubstituter.new(30_016, 27_509) }
      let(:substituer2) { Chorg::Substituter::IdSubstituter.new(30_016, []) }
      let(:substituer3) { Chorg::Substituter::IdSubstituter.new(30_016, [ 27_509 ]) }
      it { expect(substituer1).to be > substituer2 }
      it { expect(substituer1).to be > substituer3 }
      it { expect(substituer2).to be > substituer3 }
    end
  end
end

describe Chorg::Substituter::StringSubstituter do
  let(:group) { cms_group }
  describe "#call" do
    context "with String" do
      context "with email" do
        let(:from) { "kmsrgxit7k@example.jp" }
        let(:to) { "1b3ubagfds@example.jp" }
        subject { described_class.new(from, to) }
        it { expect(subject.call(:key, "kmsrgxit7k@example.jp", group.id)).to eq "1b3ubagfds@example.jp" }
        it { expect(subject.call(:key, "purwwnlydv@example.jp", group.id)).to eq "purwwnlydv@example.jp" }
      end

      context "with group hierarchy" do
        let(:from) { "組織変更/企画政策部/企画政策部 広報課" }
        let(:to) { "組織変更/企画政策部/企画政策部 政策課" }
        subject { described_class.new(from, to) }
        it { expect(subject.call(:key, "組織変更/企画政策部/企画政策部 広報課", group.id)).to eq "組織変更/企画政策部/企画政策部 政策課" }
        it { expect(subject.call(:key, "組織変更/危機管理部/危機管理部 管理課", group.id)).to eq "組織変更/危機管理部/危機管理部 管理課" }
        it { expect(subject.call(:key, "企画政策部 広報課", group.id)).to eq "企画政策部 広報課" }
        it { expect(subject.call(:key, "危機管理部 管理課", group.id)).to eq "危機管理部 管理課" }
      end
    end
  end

  describe "#<=>" do
    let(:substituer1) { described_class.new("kmsrgxit7k@example.jp", "tfszbhe91d@example.jp") }
    let(:substituer2) { described_class.new("kmsrgxit7k", "tfszbhe91d") }
    let(:substituer3) { described_class.new("組織変更/企画政策部/企画政策部 長生き課", "組織変更/健康管理部/健康管理部 地域連携課") }
    let(:substituer4) { described_class.new("企画政策部 長生き課", "健康管理部 地域連携課") }
    let(:substituer5) { Chorg::Substituter::IdSubstituter.new(30_016, []) }

    it { expect(substituer1).to be < substituer2 }
    it { expect(substituer1).to be > substituer3 }
    it { expect(substituer1).to be < substituer4 }
    it { expect(substituer1).to be > substituer5 }

    it { expect(substituer2).to be > substituer3 }
    it { expect(substituer2).to be > substituer4 }
    it { expect(substituer2).to be > substituer5 }

    it { expect(substituer3).to be < substituer4 }
    it { expect(substituer3).to be > substituer5 }

    it { expect(substituer4).to be > substituer5 }
  end
end

describe Chorg::Substituter do
  let(:group) { cms_group }
  context "with simple substitution" do
    let(:from) do
      { id: 30_016, name: "組織変更/企画政策部/企画政策部 長生き課",
        contact_email: "kmsrgxit7k@example.jp", release_date: Time.zone.now }
    end
    let(:to) do
      { id: 31_016, name: "組織変更/健康管理部/健康管理部 地域連携課",
        contact_email: "1b3ubagfds@example.jp", release_date: Time.zone.now }
    end
    subject { described_class.collect(from, to, group.id) }

    describe "#call" do
      it { expect(subject.call(:key, 30_016, group.id)).to eq 31_016 }
      it { expect(subject.call(:key, "組織変更/企画政策部/企画政策部 長生き課", group.id)).to eq "組織変更/健康管理部/健康管理部 地域連携課" }
      it { expect(subject.call(:key, "企画政策部 長生き課", group.id)).to eq "健康管理部 地域連携課" }
      it { expect(subject.call(:key, "kmsrgxit7k@example.jp", group.id)).to eq "1b3ubagfds@example.jp" }

      # array
      it { expect(subject.call(:key, [30_016], group.id)).to eq [31_016] }

      # not replaced
      it { expect(subject.call(:key, "30_015", group.id)).to eq "30_015" }
      it { expect(subject.call(:key, "30_016", group.id)).to eq "30_016" }
    end
  end

  context "with multiple substitutions" do
    let(:from1) { { id: 30_015, name: "組織変更/企画政策部" } }
    let(:from2) do
      { id: 30_016, name: "組織変更/企画政策部/企画政策部 長生き課",
        contact_email: "kmsrgxit7k@example.jp", release_date: Time.zone.now }
    end
    let(:to1) { { id: 31_015, name: "組織変更/健康管理部" } }
    let(:to2) do
      { id: 31_016, name: "組織変更/健康管理部/健康管理部 地域連携課",
        contact_email: "1b3ubagfds@example.jp", release_date: Time.zone.now }
    end
    subject { described_class.collect(from1, to1, group.id).collect(from2, to2, group.id) }

    it { expect(subject.call(:key, 30_015, group.id)).to eq 31_015 }
    it { expect(subject.call(:key, 30_016, group.id)).to eq 31_016 }
    it { expect(subject.call(:key, "組織変更/企画政策部", group.id)).to eq "組織変更/健康管理部" }
    it { expect(subject.call(:key, "企画政策部", group.id)).to eq "健康管理部" }
    it { expect(subject.call(:key, "組織変更/企画政策部/企画政策部 長生き課", group.id)).to eq "組織変更/健康管理部/健康管理部 地域連携課" }
    it { expect(subject.call(:key, "企画政策部 長生き課", group.id)).to eq "健康管理部 地域連携課" }
    it { expect(subject.call(:key, "kmsrgxit7k@example.jp", group.id)).to eq "1b3ubagfds@example.jp" }

    # array
    it { expect(subject.call(:key, [30_015], group.id)).to eq [31_015] }
    it { expect(subject.call(:key, [30_016], group.id)).to eq [31_016] }

    # not replaced
    it { expect(subject.call(:key, "30_015", group.id)).to eq "30_015" }
    it { expect(subject.call(:key, "30_016", group.id)).to eq "30_016" }
  end

  describe "<=>" do
    subject do
      [ Chorg::Substituter::IdSubstituter.new(6, 0),
        Chorg::Substituter::IdSubstituter.new(6, [0, 0]) ]
    end
    it do
      expect { subject.sort! }.not_to raise_error
    end
  end

  describe "does not substitute to nil" do
    let(:from) do
      { id: 30_016, name: "組織変更/企画政策部/企画政策部 長生き課",
        contact_email: "kmsrgxit7k@example.jp", release_date: Time.zone.now }
    end
    let(:to) { { id: 31_016 } }
    subject { described_class.new.collect(from, to, group.id) }

    describe "#call" do
      it { expect(subject.call(:key, 30_016, group.id)).to eq 31_016 }
      it { expect(subject.call(:key, "組織変更/企画政策部/企画政策部 長生き課", group.id)).to eq "組織変更/企画政策部/企画政策部 長生き課" }
      it { expect(subject.call(:key, "企画政策部 長生き課", group.id)).to eq "企画政策部 長生き課" }
      it { expect(subject.call(:key, "kmsrgxit7k@example.jp", group.id)).to eq "kmsrgxit7k@example.jp" }
    end
  end
end
