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
    SS::Current.with(env: request, request: request) do
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

      # invalid urls
      expect(described_class.trusted_url?("https://●●")).to be_falsey
    end
  end

  describe ".trusted_url? with wildcard" do
    let(:trusted1_url) { "https://*.#{trusted1_domain}/" }
    let(:trusted_urls) { [ trusted1_url ] }

    it do
      expect(described_class.trusted_url?("https://#{unique_id}.#{trusted1_domain}/")).to be_truthy
      expect(described_class.trusted_url?("https://#{trusted1_domain}/")).to be_falsey
      expect(described_class.trusted_url?("https://#{trusted2_domain}/")).to be_falsey
      expect(described_class.trusted_url?("https://#{unique_id}.#{trusted2_domain}/")).to be_falsey
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
      expect(described_class.valid_url?(::Addressable::URI.parse("/a/b/c"))).to be_truthy
      expect(described_class.valid_url?(::Addressable::URI.parse("a/b/c"))).to be_truthy

      # relative: domain + path
      expect(described_class.valid_url?(::Addressable::URI.parse("//#{request_domain}"))).to be_truthy
      expect(described_class.valid_url?(::Addressable::URI.parse("//#{request_domain}/"))).to be_truthy
      expect(described_class.valid_url?(::Addressable::URI.parse("//#{request_domain}/#{unique_id}"))).to be_truthy
      expect(described_class.valid_url?(::Addressable::URI.parse("//#{unique_domain}"))).to be_falsey
      expect(described_class.valid_url?(::Addressable::URI.parse("//#{unique_domain}/"))).to be_falsey
      expect(described_class.valid_url?(::Addressable::URI.parse("//#{unique_domain}#{request_path}"))).to be_falsey

      # invalid urls
      expect(described_class.valid_url?(::Addressable::URI.parse("//●●"))).to be_falsey
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
      expect(described_class.valid_url?(::Addressable::URI.parse("/a/b/c"))).to be_truthy
      expect(described_class.valid_url?(::Addressable::URI.parse("a/b/c"))).to be_truthy

      # relative: domain + path
      expect(described_class.valid_url?(::Addressable::URI.parse("//#{request_domain}"))).to be_truthy
      expect(described_class.valid_url?(::Addressable::URI.parse("//#{request_domain}/"))).to be_truthy
      expect(described_class.valid_url?(::Addressable::URI.parse("//#{request_domain}/#{unique_id}"))).to be_truthy
      expect(described_class.valid_url?(::Addressable::URI.parse("//#{unique_domain}"))).to be_falsey
      expect(described_class.valid_url?(::Addressable::URI.parse("//#{unique_domain}/"))).to be_falsey
      expect(described_class.valid_url?(::Addressable::URI.parse("//#{unique_domain}#{request_path}"))).to be_falsey
    end
  end

  # Addressable ではホストなしと解析されるが、ブラウザ(WHATWG URL)では外部ホストと解釈される URL
  describe "urls interpreted as an external host by browsers" do
    let(:evil_domain) { unique_domain }
    let(:ambiguous_urls) do
      [
        "///#{evil_domain}",
        "////#{evil_domain}",
        "/\\#{evil_domain}",
        "\\\\#{evil_domain}",
        "\\/#{evil_domain}",
        "/\t/#{evil_domain}",
        "/\n/#{evil_domain}",
        " //#{evil_domain}",
        "\t//#{evil_domain}",
        "https:/#{evil_domain}",
        "https:#{evil_domain}",
        "https:///#{evil_domain}",
        "https://#{evil_domain}\\@#{request_domain}/",
        "https://#{request_domain}@#{evil_domain}/",
        "https://#{request_domain}\\#{evil_domain}/",
        "/#{unique_id}/\u0000.html",
      ]
    end

    before do
      @save_url_type = SS.config.replace_value_at(:sns, :url_type, "restricted")
      described_class.send(:clear_trusted_urls)
    end

    after do
      SS.config.replace_value_at(:sns, :url_type, @save_url_type)
      described_class.send(:clear_trusted_urls)
    end

    it do
      known_trusted_urls = [ "//#{request_domain}" ]
      ambiguous_urls.each do |url|
        expect(described_class.myself_url?(url)).to be_falsey, "expected #{url.inspect} not to be myself url"
        expect(described_class.trusted_url?(url, known_trusted_urls)).to be_falsey, "expected #{url.inspect} not to be trusted"
        expect(described_class.valid_url?(url, known_trusted_urls)).to be_falsey, "expected #{url.inspect} not to be valid"
      end

      # ブラウザが除去する前後の空白は除去してから判定する
      expect(described_class.valid_url?(" /#{unique_id}/", known_trusted_urls)).to be_truthy
      expect(described_class.valid_url?("https://#{request_domain}/#{unique_id}/ ", known_trusted_urls)).to be_truthy
      # ブラウザはパス中の "%5C" をデコードしないので、外部ホストとは解釈されない
      expect(described_class.valid_url?("/%5C#{evil_domain}", known_trusted_urls)).to be_truthy
    end
  end

  describe "#validate_each" do
    let!(:clazz) do
      Struct.new(:url) do
        include ActiveModel::Validations

        def self.model_name
          ActiveModel::Name.new(self, nil, "temp")
        end

        def fields
          { "url" => OpenStruct.new(localized?: false) }
        end
      end
    end

    before do
      clazz.validates :url, "sys/trusted_url" => true
    end

    it do
      expect(clazz.new("/#{unique_id}")).to be_valid
      expect(clazz.new("//#{request_domain}/#{unique_id}")).to be_valid
      expect(clazz.new("///#{unique_domain}")).to be_invalid
      expect(clazz.new("https:/#{unique_domain}")).to be_invalid
      # 解析できない URL は invalid
      expect(clazz.new("https://#{unique_domain}:port/")).to be_invalid
    end
  end
end
