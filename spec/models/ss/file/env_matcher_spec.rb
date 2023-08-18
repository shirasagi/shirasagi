require 'spec_helper'

describe SS::Addon::FileSetting::EnvMatcher, dbscope: :example do
  # nginx でクライアント証明書を認証すると $ssl_client_s_dn に Subject が、$ssl_client_i_dn に Issuer がセットされる。
  # proxy_set_header X-SSL_CLIENT_S_DN \$ssl_client_s_dn; のような設定で、シラサギまで伝播してもらう想定
  let(:key) { "X-SSL_CLIENT_S_DN" }
  let(:value) { "C=JP,O=JPNIC,OU=security,CN=#{unique_id}" }

  before do
    SS::LogSupport.stdout_logger.enable
  end

  after do
    SS::LogSupport.stdout_logger.disable(false)
  end

  context "when value is given" do
    it do
      matcher = described_class.new(key, value)

      expect(matcher.match?(ActionDispatch::Request.new(key => value))).to be_truthy

      value2 = unique_id
      expect(matcher.match?(ActionDispatch::Request.new(key => value2))).to be_falsey
      expect(matcher.match?(ActionDispatch::Request.new(unique_id.upcase => value))).to be_falsey

      expect { SS::LogSupport.stdout_logger.disable(true) }.to \
        output(include("environment value '#{value2}' is not matched", "environment key '#{key}' is not presented")).to_stdout
    end
  end

  context "when only key is given" do
    it do
      matcher = described_class.new(key)

      # この設定では値は問わない。何でも良いのでクライアント認証がなされていれば OK とする
      expect(matcher.match?(ActionDispatch::Request.new(key => value))).to be_truthy
      expect(matcher.match?(ActionDispatch::Request.new(key => unique_id))).to be_truthy

      expect(matcher.match?(ActionDispatch::Request.new(unique_id.upcase => value))).to be_falsey

      expect { SS::LogSupport.stdout_logger.disable(true) }.to \
        output(include("environment key '#{key}' is not presented")).to_stdout
    end
  end
end
