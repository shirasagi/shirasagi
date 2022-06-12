require 'spec_helper'

describe Cms::FormDb, dbscope: :example do
  context "import" do
    subject { Cms::FormDb.new }

    it do
      expect(subject.condition_match?('abc', 'any_of', %w(abc xyz))).to be_truthy
      expect(subject.condition_match?('abc', 'any_of', %w(abz xyz))).to be_falsey
      expect(subject.condition_match?('abc', 'none_of', %w(abz xyz))).to be_truthy
      expect(subject.condition_match?('abc', 'none_of', %w(abc xyz))).to be_falsey
      expect(subject.condition_match?('abc', 'start_with', %w(a x))).to be_truthy
      expect(subject.condition_match?('abc', 'start_with', %w(b x))).to be_falsey
      expect(subject.condition_match?('abc', 'end_with', %w(c x))).to be_truthy
      expect(subject.condition_match?('abc', 'end_with', %w(b x))).to be_falsey
      expect(subject.condition_match?('abc', 'include_any_of', %w(x y a))).to be_truthy
      expect(subject.condition_match?('abc', 'include_any_of', %w(x y z))).to be_falsey
      expect(subject.condition_match?('abc', 'include_none_of', %w(x y z))).to be_truthy
      expect(subject.condition_match?('abc', 'include_none_of', %w(x y a))).to be_falsey
    end
  end
end
