require 'spec_helper'

describe IpAddressValidator, type: :validator do
  let!(:clazz) do
    Struct.new(:ip_addr) do
      include ActiveModel::Validations
      def self.model_name
        ActiveModel::Name.new(self, nil, "temp")
      end
      validates :ip_addr, ip_address: true
    end
  end

  context 'with valid ip v4 address' do
    subject! { clazz.new("192.168.10.5") }

    it do
      expect(subject).to be_valid
    end
  end

  context 'with valid ip v4 network address' do
    subject! { clazz.new("192.168.10.0/24") }

    it do
      expect(subject).to be_valid
    end
  end

  context 'with valid ip v4 address array' do
    subject! { clazz.new(%w(192.168.10.5 192.168.10.6)) }

    it do
      expect(subject).to be_valid
    end
  end

  context 'with valid ip v4 address with comment' do
    subject! { clazz.new([ "# comment", "192.168.10.6" ]) }

    it do
      expect(subject).to be_valid
    end
  end

  context 'with valid ip v6 unicast address' do
    subject! { clazz.new("1080:0:0:0:8:800:200C:417A") }

    it do
      expect(subject).to be_valid
    end
  end

  context 'with valid ip v6 loopback address' do
    subject! { clazz.new("::1") }

    it do
      expect(subject).to be_valid
    end
  end

  context 'with valid ip v6 network address' do
    subject! { clazz.new("2001:0DB8:0:CD30::/60") }

    it do
      expect(subject).to be_valid
    end
  end

  context 'with invalid ip address' do
    subject! { clazz.new("foo") }

    it do
      expect(subject).to be_invalid
      expect(subject.errors[:ip_addr]).to eq [ I18n.t("errors.messages.invalid") ]
    end
  end
end
