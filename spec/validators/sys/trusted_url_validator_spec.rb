require 'spec_helper'

describe Sys::TrustedUrlValidator, type: :validator, dbscope: :example do
  describe ".myself_url?" do
    let(:base_url) { unique_url }
    let(:request) { OpenStruct.new(url: base_url) }

    before do
      # Rails.application.current_request = request
      Thread.current["ss.env"] = request
      Thread.current["ss.request"] = request
    end

    after do
      # Rails.application.current_request = nil
      Thread.current["ss.env"] = nil
      Thread.current["ss.request"] = nil
    end

    it do
      expect(described_class.myself_url?(::Addressable::URI.parse(base_url))).to be_truthy
      expect(described_class.myself_url?(::Addressable::URI.parse("#{base_url}/aaa/bbb"))).to be_truthy
      expect(described_class.myself_url?(::Addressable::URI.parse(unique_url))).to be_falsey
    end
  end

  describe ".trusted_url?" do
    let(:trusted_url) { unique_url }
    let(:trusted_urls) { [ trusted_url ] }

    before do
      @save = SS.config.cms.trusted_urls
      SS.config.replace_value_at(:sns, :trusted_urls, trusted_urls)
    end

    after do
      SS.config.replace_value_at(:sns, :trusted_urls, @save)
    end

    it do
      expect(described_class.trusted_url?(::Addressable::URI.parse(trusted_url))).to be_truthy
      expect(described_class.trusted_url?(::Addressable::URI.parse("#{trusted_url}/aaa/bbb"))).to be_falsey
      expect(described_class.trusted_url?(::Addressable::URI.parse(unique_url))).to be_falsey
    end
  end

  describe ".valid_url?" do
    it do
      expect(described_class.valid_url?(::Addressable::URI.parse("/a/b/c"))).to be_truthy
      expect(described_class.valid_url?(::Addressable::URI.parse("a/b/c"))).to be_falsey
    end
  end
end
