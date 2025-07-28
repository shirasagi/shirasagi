require 'spec_helper'

describe SS::ColorValidator, type: :validator do
  subject { build :gws_schedule_plan, color: value }

  context 'with nil' do
    let(:value) { nil }

    it do
      is_expected.to be_valid
    end
  end

  context 'with blank' do
    let(:value) { '' }

    it do
      is_expected.to be_valid
    end
  end

  context 'with black' do
    let(:value) { '#000000' }

    it do
      is_expected.to be_valid
    end
  end

  context 'with white (lowercase)' do
    let(:value) { '#ffffff'.downcase }

    it do
      is_expected.to be_valid
    end
  end

  context 'with white (uppercase)' do
    let(:value) { '#ffffff'.upcase }

    it do
      is_expected.to be_valid
    end
  end

  context 'not staring with "#"' do
    let(:value) { 'ffffff' }

    it do
      is_expected.to be_valid
    end
  end

  context "length isn't 7" do
    let(:value) { '#fff' }

    it do
      is_expected.to be_valid
    end
  end

  context "not hex decimal" do
    let(:value) { '#ghijkl' }

    it do
      is_expected.to be_invalid
    end
  end
end
