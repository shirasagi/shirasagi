require 'spec_helper'

describe Cms::LoopSetting, dbscope: :example do
  describe ".search" do
    context "when nil is given" do
      subject { described_class.search(nil) }
      it { expect(subject.selector.to_h).to be_empty }
    end

    context "when name is given" do
      subject { described_class.search(name: "名前 なまえ") }
      it { expect(subject.selector.to_h).to include("name" => include("$all" => include(/名前/i, /なまえ/i))) }
    end

    context "when name includes regex meta characters" do
      subject { described_class.search(name: "名|前 な(*.?)まえ") }
      it { expect(subject.selector.to_h).to include("name" => include("$all" => include(/名\|前/i, /な\(\*\.\?\)まえ/i))) }
    end

    context "when keyword is given" do
      subject { described_class.search(keyword: "キーワード1 キーワード2") }
      it { expect(subject.selector.to_h).to include("$and" => include("$or" => include("name" => /キーワード1/i))) }
      it { expect(subject.selector.to_h).to include("$and" => include("$or" => include("name" => /キーワード2/i))) }
    end
  end
end
