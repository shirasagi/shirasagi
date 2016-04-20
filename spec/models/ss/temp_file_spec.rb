require 'spec_helper'

describe SS::TempFile do
  describe "empty" do
    subject { described_class.new }
    its(:valid?) { is_expected.to be_falsey }
  end

  describe "factory girl" do
    subject { create :ss_temp_file }
    its(:valid?) { is_expected.to be_truthy }
  end
end
