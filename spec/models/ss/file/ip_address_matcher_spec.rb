require 'spec_helper'

describe SS::Addon::FileSetting::IPAddressMatcher, dbscope: :example do
  before do
    SS::LogSupport.enable
  end

  after do
    SS::LogSupport.disable(false)
  end

  context "with specific addresses" do
    it do
      matcher = described_class.new(%w(192.168.10.1 192.168.10.2))

      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.10.1" }))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.10.2" }))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.10.3" }))).to be_falsey

      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.10.1"))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.10.2"))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.10.4"))).to be_falsey

      expect { SS::LogSupport.disable(true) }.to \
        output(include("remote address '192.168.10.3' is not allowed", "remote address '192.168.10.4' is not allowed")).to_stdout
    end
  end

  context "with network addresses" do
    it do
      matcher = described_class.new("192.168.10.0/24")

      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.10.1" }))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.10.2" }))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.10.255" }))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.11.1" }))).to be_falsey

      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.10.1"))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.10.2"))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.10.255"))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.11.2"))).to be_falsey

      expect { SS::LogSupport.disable(true) }.to \
        output(include("remote address '192.168.11.1' is not allowed", "remote address '192.168.11.2' is not allowed")).to_stdout
    end
  end

  context "with network addresses (bit mask)" do
    it do
      matcher = described_class.new("192.168.10.0/255.255.255.0")

      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.10.1" }))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.10.2" }))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.10.255" }))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.11.1" }))).to be_falsey

      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.10.1"))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.10.2"))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.10.255"))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.11.2"))).to be_falsey

      expect { SS::LogSupport.disable(true) }.to \
        output(include("remote address '192.168.11.1' is not allowed", "remote address '192.168.11.2' is not allowed")).to_stdout
    end
  end

  context "with comments and blanks" do
    it do
      matcher = described_class.new([ " # comments here    ", "  192.168.10.1  ", "  ", "  192.168.10.2  " ])

      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.10.1" }))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.10.2" }))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: { "HTTP_X_REAL_IP" => "192.168.10.3" }))).to be_falsey

      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.10.1"))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.10.2"))).to be_truthy
      expect(matcher.match?(OpenStruct.new(env: {}, remote_addr: "192.168.10.4"))).to be_falsey

      expect { SS::LogSupport.disable(true) }.to \
        output(include("remote address '192.168.10.3' is not allowed", "remote address '192.168.10.4' is not allowed")).to_stdout
    end
  end
end
