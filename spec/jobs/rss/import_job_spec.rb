require 'spec_helper'

describe Rss::ImportJob, dbscope: :example do
  before do
    WebMock.reset!

    chain = stub_request(:get, url)
    chain = chain.to_return(status: 200, body: ::File.read(Rails.root.join("spec", "fixtures", "rss", path)), headers: {})
    if respond_to?(:path2)
      chain = chain.to_return(status: 200, body: ::File.read(Rails.root.join("spec", "fixtures", "rss", path2)), headers: {})
    end
    chain.to_return(status: 404)
  end

  after { WebMock.reset! }

  context "when importing rdf" do
    let(:path) { "sample-rdf.xml" }
    let(:url) { "http://#{unique_domain}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site, rss_url: url }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    it do
      expect { described_class.bind(bindings).perform_now }.to change { Rss::Page.count }.from(0).to(5)
      expect(Rss::Page.where(rss_link: "http://example.jp/rdf/1.html").first).not_to be_nil
    end
  end

  context "when importing rss" do
    let(:path) { "sample-rss.xml" }
    let(:url) { "http://#{unique_domain}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site, rss_url: url }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    it do
      expect { described_class.bind(bindings).perform_now }.to change { Rss::Page.count }.from(0).to(5)
      expect(Rss::Page.where(rss_link: "http://example.jp/rss/1.html").first).not_to be_nil
    end
  end

  context "when importing atom" do
    let(:path) { "sample-atom.xml" }
    let(:url) { "http://#{unique_domain}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site, rss_url: url }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    it do
      expect { described_class.bind(bindings).perform_now }.to change { Rss::Page.count }.from(0).to(5)
      expect(Rss::Page.where(rss_link: "http://example.jp/atom/1.html").first).not_to be_nil
    end
  end

  describe ".import_jobs" do
    context "rss_refresh_method is auto" do
      let(:path) { "sample-rdf.xml" }
      let(:url) { "http://#{unique_domain}/#{path}" }
      let(:site) { cms_site }
      let(:user) { cms_user }
      let(:refresh_method) { Rss::Node::Page::RSS_REFRESH_METHOD_AUTO }
      let!(:node) { create :rss_node_page, site: site, rss_url: url, rss_refresh_method: refresh_method }

      it do
        described_class.perform_jobs(site, user)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end
      end
    end

    context "rss_refresh_method is manual" do
      let(:path) { "sample-rdf.xml" }
      let(:url) { "http://#{unique_domain}/#{path}" }
      let(:site) { cms_site }
      let(:user) { cms_user }
      let(:refresh_method) { Rss::Node::Page::RSS_REFRESH_METHOD_MANUAL }
      let!(:node) { create :rss_node_page, site: site, rss_url: url, rss_refresh_method: refresh_method }

      it do
        described_class.perform_jobs(site, user)
        expect(Job::Log.count).to eq 0
      end
    end
  end

  context "when rss_max_docs is 3" do
    let(:path) { "sample-rdf.xml" }
    let(:url) { "http://#{unique_domain}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site, rss_url: url, rss_max_docs: 3 }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    it do
      expect { described_class.bind(bindings).perform_now }.to change { Rss::Page.count }.from(0).to(3)
    end
  end

  context "when rss is not changed" do
    let(:path) { "sample-rdf.xml" }
    let(:url) { "http://#{unique_domain}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site, rss_url: url }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    it do
      described_class.bind(bindings).perform_now
      expect(Rss::Page.count).to eq 5

      described_class.bind(bindings).perform_now
      # expected count is 5.
      expect(Rss::Page.count).to eq 5

      # doc1 is not changed.
      doc1 = Rss::Page.where(rss_link: "http://example.jp/rdf/1.html").first
      expect(doc1).not_to be_nil
      expect(doc1.name).to eq '記事1'
      expect(doc1.released).to eq Time.zone.parse('2015-06-12T19:00:00+09:00')
      # doc2 is not changed.
      doc2 = Rss::Page.where(rss_link: "http://example.jp/rdf/2.html").first
      expect(doc2).not_to be_nil
      expect(doc2.name).to eq '記事2'
      expect(doc2.released).to eq Time.zone.parse('2015-06-11T14:00:00+09:00')
      # doc3 is not changed.
      doc3 = Rss::Page.where(rss_link: "http://example.jp/rdf/3.html").first
      expect(doc3).not_to be_nil
      expect(doc3.name).to eq '記事3'
      expect(doc3.released).to eq Time.zone.parse('2015-06-10T09:00:00+09:00')
      # doc4 is not changed.
      doc4 = Rss::Page.where(rss_link: "http://example.jp/rdf/4.html").first
      expect(doc4).not_to be_nil
      expect(doc4.name).to eq '記事4'
      expect(doc4.released).to eq Time.zone.parse('2015-06-09T15:00:00+09:00')
      # doc5 is not changed.
      doc5 = Rss::Page.where(rss_link: "http://example.jp/rdf/5.html").first
      expect(doc5).not_to be_nil
      expect(doc5.name).to eq '記事5'
      expect(doc5.released).to eq Time.zone.parse('2015-06-08T10:00:00+09:00')
    end
  end

  context "when rss is updated" do
    let(:path) { "sample-rdf.xml" }
    let(:path2) { "sample-rdf-2.xml" }
    let(:url) { "http://#{unique_domain}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site, rss_url: url }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    it do
      described_class.bind(bindings).perform_now
      expect(Rss::Page.count).to eq 5

      described_class.bind(bindings).perform_now
      # expected count is 3, 1 added, 3 deleted, 1 updated.
      expect(Rss::Page.count).to eq 3

      # doc1 is updated.
      doc1 = Rss::Page.where(rss_link: "http://example.jp/rdf/1.html").first
      expect(doc1).not_to be_nil
      expect(doc1.name).to eq '【更新】記事1'
      expect(doc1.released).to eq Time.zone.parse('2015-06-13T11:00:00+09:00')
      # doc2 is deleted.
      doc2 = Rss::Page.where(rss_link: "http://example.jp/rdf/2.html").first
      expect(doc2).to be_nil
      # doc3 is not changed.
      doc3 = Rss::Page.where(rss_link: "http://example.jp/rdf/3.html").first
      expect(doc3).not_to be_nil
      expect(doc3.name).to eq '記事3'
      expect(doc3.released).to eq Time.zone.parse('2015-06-10T09:00:00+09:00')
      # doc4 is deleted.
      doc4 = Rss::Page.where(rss_link: "http://example.jp/rdf/4.html").first
      expect(doc4).to be_nil
      # doc5 is deleted.
      doc5 = Rss::Page.where(rss_link: "http://example.jp/rdf/5.html").first
      expect(doc5).to be_nil
      # doc6 is added.
      doc6 = Rss::Page.where(rss_link: "http://example.jp/rdf/6.html").first
      expect(doc6).not_to be_nil
    end
  end

  context "when first rss and last rss was deleted" do
    let(:path) { "sample-rdf.xml" }
    let(:path2) { "sample-rdf-3.xml" }
    let(:url) { "http://#{unique_domain}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site, rss_url: url }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.host, node_id: node.id, user_id: user.id } }

    it do
      described_class.bind(bindings).perform_now
      expect(Rss::Page.count).to eq 5

      # http.options real_path: "/sample-rdf-3.xml"

      described_class.bind(bindings).perform_now
      # expected count is 3, 2 deleted.
      expect(Rss::Page.count).to eq 3

      # doc1 is deleted.
      doc1 = Rss::Page.where(rss_link: "http://example.jp/rdf/1.html").first
      expect(doc1).to be_nil
      # doc2 is not changed.
      doc3 = Rss::Page.where(rss_link: "http://example.jp/rdf/2.html").first
      expect(doc3).not_to be_nil
      expect(doc3.name).to eq '記事2'
      expect(doc3.released).to eq Time.zone.parse('2015-06-11T14:00:00+09:00')
      # doc3 is not changed.
      doc3 = Rss::Page.where(rss_link: "http://example.jp/rdf/3.html").first
      expect(doc3).not_to be_nil
      expect(doc3.name).to eq '記事3'
      expect(doc3.released).to eq Time.zone.parse('2015-06-10T09:00:00+09:00')
      # doc4 is not changed.
      doc3 = Rss::Page.where(rss_link: "http://example.jp/rdf/4.html").first
      expect(doc3).not_to be_nil
      expect(doc3.name).to eq '記事4'
      expect(doc3.released).to eq Time.zone.parse('2015-06-09T15:00:00+09:00')
      # doc5 is deleted.
      doc5 = Rss::Page.where(rss_link: "http://example.jp/rdf/5.html").first
      expect(doc5).to be_nil
    end
  end
end
