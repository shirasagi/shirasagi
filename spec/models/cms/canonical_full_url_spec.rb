require 'spec_helper'

describe Cms, type: :model, dbscope: :example do
  let!(:site) { cms_site }

  describe ".canonical_full_url" do
    it do
      expect(Cms.canonical_full_url(site, "/news/")).to eq "#{site.full_root_url}news/"
      expect(Cms.canonical_full_url(site, "/news/index.html")).to eq "#{site.full_root_url}news/"
      expect(Cms.canonical_full_url(site, "/news")).to eq "#{site.full_root_url}news/"
      expect(Cms.canonical_full_url(site, "/news/index.p2.html")).to eq "#{site.full_root_url}news/index.p2.html"
      expect(Cms.canonical_full_url(site, "/docs/926.html")).to eq "#{site.full_root_url}docs/926.html"
    end
  end
end
