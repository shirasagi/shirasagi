require 'spec_helper'

describe EmailValidator, type: :validator do
  context "plain email address is expected" do
    let(:model_class) do
      Struct.new(:email) do
        include ActiveModel::Validations

        def self.name
          @name ||= unique_id
        end

        validates :email, email: true
      end
    end

    subject { model_class.new value }

    context 'invalid email address' do
      let(:value) { unique_id }

      it do
        is_expected.to be_invalid
      end
    end

    context 'valid email address' do
      let(:value) { "#{unique_id}@example.jp" }

      it do
        is_expected.to be_valid
      end
    end

    context 'valid RFC2822 email address' do
      let(:value) { "Given Family <#{unique_id}@example.jp>" }

      it do
        is_expected.to be_invalid
      end
    end

    context 'valid complex RFC2822 email address' do
      let(:value) { 'Mikel Lindsaar (My email address) <mikel@test.lindsaar.net>' }

      it do
        is_expected.to be_invalid
      end
    end
  end

  context "RFC2822 email address is allowed" do
    let(:model_class) do
      Struct.new(:email) do
        include ActiveModel::Validations

        def self.name
          @name ||= unique_id
        end

        validates :email, email: { rfc2822: true }
      end
    end

    subject { model_class.new value }

    context 'invalid email address' do
      let(:value) { unique_id }

      it do
        is_expected.to be_invalid
      end
    end

    context 'valid email address' do
      let(:value) { "#{unique_id}@example.jp" }

      it do
        is_expected.to be_valid
      end
    end

    context 'valid RFC2822 email address' do
      let(:value) { "Given Family <#{unique_id}@example.jp>" }

      it do
        is_expected.to be_valid
      end
    end

    context 'valid complex RFC2822 email address' do
      let(:value) { 'Mikel Lindsaar (My email address) <mikel@test.lindsaar.net>' }

      it do
        is_expected.to be_valid
      end
    end
  end
end
