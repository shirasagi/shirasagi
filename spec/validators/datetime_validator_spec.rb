require 'spec_helper'

describe DatetimeValidator, type: :validator do
  subject { build :gws_user_title, expiration_date: value }

  context 'invalid date' do
    let(:value) { '2016/13/01' }
    it { is_expected.not_to be_valid }
  end

  context 'valid date' do
    let(:value) { '2016/01/01' }
    it { is_expected.to be_valid }
  end

  context 'invalid datetime' do
    let(:value) { '2016/1/01 30:00' }
    it { is_expected.not_to be_valid }
  end

  context 'valid datetime' do
    let(:value) { '2016/01/01 00:00' }
    it { is_expected.to be_valid }
  end
end
