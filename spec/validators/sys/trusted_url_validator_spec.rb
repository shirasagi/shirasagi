require 'spec_helper'

describe Sys::TrustedUrlValidator, type: :validator, dbscope: :example do
  let(:request_domain) { unique_domain }
  let(:request_path) { unique_id }
  let(:request_url) { "#{%w(http https).sample}://#{request_domain}/#{request_path}" }
  let(:request) { OpenStruct.new(url: request_url) }

  let(:trusted1_domain) { unique_domain }
  let(:trusted1_path) { unique_id }
  let(:trusted1_url) { "https://#{trusted1_domain}/#{trusted1_path}" }
  let(:trusted2_domain) { unique_domain }
  let(:trusted2_path) { unique_id }
  let(:trusted2_url) { "//#{trusted2_domain}/#{trusted2_path}" }
  let(:trusted_urls) { [ trusted1_url, trusted2_url ] }

  around do |example|
    # Rails.application.current_request = request
    SS::Current.set(env: request, request: request) do
      example.run
    end
  end

  before do
    @save_trusted_urls = SS.config.replace_value_at(:sns, :trusted_urls, trusted_urls)
    described_class.send(:clear_trusted_urls)
  end

  after do
    SS.config.replace_value_at(:sns, :trusted_urls, @save_trusted_urls)
    described_class.send(:clear_trusted_urls)
  end

  describe ".myself_url?" do
    it do
      # full url
      expect(described_class.myself_url?(request_url)).to be_truthy
      expect(described_class.myself_url?("#{request_url}/aaa/bbb")).to be_truthy

      # relative
      expect(described_class.myself_url?(unique_id)).to be_truthy
      expect(described_class.myself_url?("/#{unique_id}")).to be_truthy
      expect(described_class.myself_url?("/#{request_path}")).to be_truthy
      expect(described_class.myself_url?("//#{request_domain}/#{request_path}")).to be_truthy

      expect(described_class.myself_url?(unique_url)).to be_falsey
      expect(described_class.myself_url?("//#{unique_domain}/#{unique_id}")).to be_falsey
    end
  end

  describe ".trusted_url?" do
    it do
      # trusted1: absolute full url
      expect(described_class.trusted_url?(trusted1_url)).to be_truthy
      expect(described_class.trusted_url?("#{trusted1_url}/aaa/bbb")).to be_truthy
      # missing path
      expect(described_class.trusted_url?("https://#{trusted1_domain}/")).to be_falsey
      # protocol mismatch
      expect(described_class.trusted_url?("http://#{trusted1_domain}/#{trusted1_path}")).to be_falsey

      # trusted2: relative url
      expect(described_class.trusted_url?(trusted2_url)).to be_truthy
      expect(described_class.trusted_url?("#{trusted2_url}/#{unique_id}")).to be_truthy
      expect(described_class.trusted_url?("http://#{trusted2_domain}/#{trusted2_path}/")).to be_truthy
      expect(described_class.trusted_url?("https://#{trusted2_domain}/#{trusted2_path}/")).to be_truthy

      # relative path
      expect(described_class.trusted_url?("/")).to be_truthy
      expect(described_class.trusted_url?("/#{unique_id}")).to be_truthy
      expect(described_class.trusted_url?("./#{unique_id}")).to be_truthy
      expect(described_class.trusted_url?(unique_id)).to be_truthy

      expect(described_class.trusted_url?(unique_url)).to be_falsey
    end
  end

  describe ".valid_url?" do
    before do
      @save_url_type = SS.config.replace_value_at(:sns, :url_type, "restricted")
      Sys::TrustedUrlValidator.send(:clear_trusted_urls)
    end

    after do
      SS.config.replace_value_at(:sns, :url_type, @save_url_type)
      Sys::TrustedUrlValidator.send(:clear_trusted_urls)
    end

    it do
      expect(described_class.url_restricted?).to be_truthy

      # relative: path only
      expect(described_class.valid_url?(Addressable::URI.parse("/a/b/c"))).to be_truthy
      expect(described_class.valid_url?(Addressable::URI.parse("a/b/c"))).to be_truthy

      # relative: domain + path
      expect(described_class.valid_url?(Addressable::URI.parse("//#{request_domain}"))).to be_truthy
      expect(described_class.valid_url?(Addressable::URI.parse("//#{request_domain}/"))).to be_truthy
      expect(described_class.valid_url?(Addressable::URI.parse("//#{request_domain}/#{unique_id}"))).to be_truthy
      expect(described_class.valid_url?(Addressable::URI.parse("//#{unique_domain}"))).to be_falsey
      expect(described_class.valid_url?(Addressable::URI.parse("//#{unique_domain}/"))).to be_falsey
      expect(described_class.valid_url?(Addressable::URI.parse("//#{unique_domain}#{request_path}"))).to be_falsey
    end
  end

  describe ".valid_url? with any url allowed" do
    before do
      @save_url_type = SS.config.replace_value_at(:sns, :url_type, 'any')
      described_class.send(:clear_trusted_urls)
    end

    after do
      SS.config.replace_value_at(:sns, :url_type, @save_url_type)
      described_class.send(:clear_trusted_urls)
    end

    it do
      expect(described_class.url_restricted?).to be_falsey

      # relative: path only
      expect(described_class.valid_url?(Addressable::URI.parse("/a/b/c"))).to be_truthy
      expect(described_class.valid_url?(Addressable::URI.parse("a/b/c"))).to be_truthy

      # relative: domain + path
      expect(described_class.valid_url?(Addressable::URI.parse("//#{request_domain}"))).to be_truthy
      expect(described_class.valid_url?(Addressable::URI.parse("//#{request_domain}/"))).to be_truthy
      expect(described_class.valid_url?(Addressable::URI.parse("//#{request_domain}/#{unique_id}"))).to be_truthy
      expect(described_class.valid_url?(Addressable::URI.parse("//#{unique_domain}"))).to be_falsey
      expect(described_class.valid_url?(Addressable::URI.parse("//#{unique_domain}/"))).to be_falsey
      expect(described_class.valid_url?(Addressable::URI.parse("//#{unique_domain}#{request_path}"))).to be_falsey
    end
  end
end
