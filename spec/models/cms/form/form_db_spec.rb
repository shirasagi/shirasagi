require 'spec_helper'

describe Cms::FormDb, dbscope: :example do
  context "import" do
    subject { Cms::FormDb.new }

    it do
      expect(subject.condition_match?('abc', 'any_of', %w(xyz abc))).to be_truthy
      expect(subject.condition_match?('abc', 'any_of', %w(xyz abz))).to be_falsey
      expect(subject.condition_match?('abc', 'none_of', %w(xyz abz))).to be_truthy
      expect(subject.condition_match?('abc', 'none_of', %w(xyz abc))).to be_falsey
      expect(subject.condition_match?('abc', 'start_with', %w(x a))).to be_truthy
      expect(subject.condition_match?('abc', 'start_with', %w(x b))).to be_falsey
      expect(subject.condition_match?('abc', 'end_with', %w(x c))).to be_truthy
      expect(subject.condition_match?('abc', 'end_with', %w(x b))).to be_falsey
      expect(subject.condition_match?('abc', 'include_any_of', %w(x y a))).to be_truthy
      expect(subject.condition_match?('abc', 'include_any_of', %w(x y z))).to be_falsey
      expect(subject.condition_match?('abc', 'include_none_of', %w(x y z))).to be_truthy
      expect(subject.condition_match?('abc', 'include_none_of', %w(x y a))).to be_falsey
    end
  end
end
