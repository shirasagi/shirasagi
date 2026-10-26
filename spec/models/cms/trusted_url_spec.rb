require 'spec_helper'

describe Cms, type: :model, dbscope: :example do
  let!(:site1) { create :cms_site_unique }
  let!(:site2) { create :cms_site_subdir, parent: site1 }

  describe ".trusted_url?" do
    before do
      # 前提条件
      expect(site1.domain).not_to eq site2.domain
    end

    it do
      unique_url.tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_falsey
        expect(described_class.trusted_url?(site2, url)).to be_falsey
      end
      "/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_truthy
        expect(described_class.trusted_url?(site2, url)).to be_truthy
      end
      "/#{site2.subdir}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_truthy
        expect(described_class.trusted_url?(site2, url)).to be_truthy
      end
      "//#{site1.domain}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_truthy
        expect(described_class.trusted_url?(site2, url)).to be_falsey
      end
      "//#{site2.domain}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_falsey
        expect(described_class.trusted_url?(site2, url)).to be_falsey
      end
      "//#{site2.domain}/#{site2.subdir}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_falsey
        expect(described_class.trusted_url?(site2, url)).to be_truthy
      end
      "http://#{site1.domain}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_truthy
        expect(described_class.trusted_url?(site2, url)).to be_falsey
      end
      "http://#{site2.domain}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_falsey
        expect(described_class.trusted_url?(site2, url)).to be_falsey
      end
      "http://#{site2.domain}/#{site2.subdir}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_falsey
        expect(described_class.trusted_url?(site2, url)).to be_truthy
      end
      "https://#{site1.domain}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_truthy
        expect(described_class.trusted_url?(site2, url)).to be_falsey
      end
      "https://#{site2.domain}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_falsey
        expect(described_class.trusted_url?(site2, url)).to be_falsey
      end
      "https://#{site2.domain}/#{site2.subdir}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_falsey
        expect(described_class.trusted_url?(site2, url)).to be_truthy
      end
      "ftp://#{site1.domain}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_falsey
        expect(described_class.trusted_url?(site2, url)).to be_falsey
      end
      "ftp://#{site2.domain}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_falsey
        expect(described_class.trusted_url?(site2, url)).to be_falsey
      end
      "ftp://#{site2.domain}/#{site2.subdir}/abc".tap do |url|
        expect(described_class.trusted_url?(site1, url)).to be_falsey
        expect(described_class.trusted_url?(site2, url)).to be_falsey
      end
    end
  end
end
