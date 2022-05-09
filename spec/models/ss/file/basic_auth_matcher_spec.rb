require 'spec_helper'

describe SS::Addon::FileSetting::BasicAuthMatcher, dbscope: :example do
  let(:id) { unique_id }
  let(:pass) { unique_id }
  let(:digest) { Base64.encode64("#{id}:#{pass}").chomp }

  before do
    SS::LogSupport.stdout_logger.enable
  end

  after do
    SS::LogSupport.stdout_logger.disable(false)
  end

  it do
    matcher = described_class.new(id, pass)

    expect(matcher.match?(ActionDispatch::Request.new("HTTP_AUTHORIZATION" => "Basic #{digest}"))).to be_truthy
    expect(matcher.match?(ActionDispatch::Request.new("X-HTTP_AUTHORIZATION" => "Basic #{digest}"))).to be_truthy
    expect(matcher.match?(ActionDispatch::Request.new("X_HTTP_AUTHORIZATION" => "Basic #{digest}"))).to be_truthy
    expect(matcher.match?(ActionDispatch::Request.new("REDIRECT_X_HTTP_AUTHORIZATION" => "Basic #{digest}"))).to be_truthy

    expect(matcher.match?(ActionDispatch::Request.new("HTTP_AUTHORIZATION" => "Digest #{digest}"))).to be_falsey
    expect(matcher.match?(ActionDispatch::Request.new("HTTP_AUTHORIZATION" => "Basic #{unique_id}"))).to be_falsey
    expect(matcher.match?(ActionDispatch::Request.new({}))).to be_falsey

    [ "authorization is not presented",
      "authorization type is not 'basic'",
      "authorization credential is not matched" ].tap do |messages|
      expect { SS::LogSupport.stdout_logger.disable(true) }.to output(include(*messages)).to_stdout
    end
  end
end
