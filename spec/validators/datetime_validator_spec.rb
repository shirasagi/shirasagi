require 'spec_helper'

describe DatetimeValidator, type: :validator do
  subject { build :gws_user_title, expiration_date: value }

  context 'invalid date' do
    let(:value) { '2016/13/01' }
    it do
      is_expected.to be_valid
      is_expected.expiration_date.to be_nil
    end
  end

  context 'valid date' do
    let(:value) { '2016/01/01' }
    it do
      is_expected.to be_valid
      is_expected.expiration_date.not_to be_nil
    end
  end

  context 'invalid datetime' do
    let(:value) { '2016/1/01 30:00' }
    it do
      is_expected.to be_valid
      is_expected.expiration_date.to be_nil
    end
  end

  context 'valid datetime' do
    let(:value) { '2016/01/01 00:00' }
    it do
      is_expected.to be_valid
      is_expected.expiration_date.not_to be_nil
    end
  end
end
