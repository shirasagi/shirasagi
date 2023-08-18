require 'spec_helper'

describe EmailsValidator, type: :validator do
  let(:model_class) do
    Struct.new(:emails) do
      include ActiveModel::Validations

      def self.name
        @name ||= unique_id
      end

      validates :emails, emails: true
    end
  end

  subject { model_class.new value }

  context 'invalid email address' do
    let(:value) { [ unique_id ] }

    it do
      is_expected.to be_invalid
    end
  end

  context 'valid email address' do
    let(:value) { [ "#{unique_id}@example.jp" ] }

    it do
      is_expected.to be_valid
    end
  end

  context 'contains invalid email address' do
    let(:value) { [ "#{unique_id}@example.jp", unique_id ] }

    it do
      is_expected.to be_invalid
    end
  end

  context 'empty email address' do
    let(:value) { [ "", nil ] }

    it do
      is_expected.to be_valid
    end
  end
end
