require 'spec_helper'

describe Rss::ImportJob, dbscope: :example,
         http_server: true, doc_root: Rails.root.join("spec", "fixtures", "rss"), port: 56_273 do
  context "when importing rdf" do
    let(:path) { "sample-rdf.xml" }
    let(:url) { "http://127.0.0.1:56273/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site, rss_url: url }
    let(:user) { cms_user }

    it do
      expect { described_class.new.call(site.host, node.id, user.id) }.to change { Rss::Page.count }.from(0).to(5)
      expect(Rss::Page.where(rss_link: "http://example.jp/rdf/1.html").first).not_to be_nil
    end
  end

  context "when importing rss" do
    let(:path) { "sample-rss.xml" }
    let(:url) { "http://127.0.0.1:56273/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site, rss_url: url }
    let(:user) { cms_user }

    it do
      expect { described_class.new.call(site.host, node.id, user.id) }.to change { Rss::Page.count }.from(0).to(5)
      expect(Rss::Page.where(rss_link: "http://example.jp/rss/1.html").first).not_to be_nil
    end
  end

  context "when importing atom" do
    let(:path) { "sample-atom.xml" }
    let(:url) { "http://127.0.0.1:56273/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site, rss_url: url }
    let(:user) { cms_user }

    it do
      expect { described_class.new.call(site.host, node.id, user.id) }.to change { Rss::Page.count }.from(0).to(5)
      expect(Rss::Page.where(rss_link: "http://example.jp/atom/1.html").first).not_to be_nil
    end
  end

  describe ".import_jobs" do
    context "rss_refresh_method is auto" do
      let(:path) { "sample-rdf.xml" }
      let(:url) { "http://127.0.0.1:56273/#{path}" }
      let(:site) { cms_site }
      let(:user) { cms_user }
      let(:refresh_method) { Rss::Node::Page::RSS_REFRESH_METHOD_AUTO }
      let!(:node) { create :rss_node_page, site: site, rss_url: url, rss_refresh_method: refresh_method }

      it do
        expect { described_class.register_jobs(site, user) }.to change(Job::Task, :count).by(1)
      end
    end

    context "rss_refresh_method is manual" do
      let(:path) { "sample-rdf.xml" }
      let(:url) { "http://127.0.0.1:56273/#{path}" }
      let(:site) { cms_site }
      let(:user) { cms_user }
      let(:refresh_method) { Rss::Node::Page::RSS_REFRESH_METHOD_MANUAL }
      let!(:node) { create :rss_node_page, site: site, rss_url: url, rss_refresh_method: refresh_method }

      it do
        expect { described_class.register_jobs(site, user) }.to change(Job::Task, :count).by(0)
      end
    end
  end

  context "when rss_max_docs is 3" do
    let(:path) { "sample-rdf.xml" }
    let(:url) { "http://127.0.0.1:56273/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site, rss_url: url, rss_max_docs: 3 }
    let(:user) { cms_user }

    it do
      expect { described_class.new.call(site.host, node.id, user.id) }.to change { Rss::Page.count }.from(0).to(3)
    end
  end

  context "when rss is updated" do
    let(:path) { "sample-rdf.xml" }
    let(:url) { "http://127.0.0.1:56273/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site, rss_url: url }
    let(:user) { cms_user }

    after do
      @http_server.options = {}
    end

    it do
      described_class.new.call(site.host, node.id, user.id)
      expect(Rss::Page.count).to eq 5

      @http_server.options = { real_path: "/sample-rdf-2.xml" }

      described_class.new.call(site.host, node.id, user.id)
      # expected count is 5, 1 added, 1 deleted, 1 updated.
      expect(Rss::Page.count).to eq 5
      # doc1 is updated.
      doc1 = Rss::Page.where(rss_link: "http://example.jp/rdf/1.html").first
      expect(doc1).not_to be_nil
      expect(doc1.name).to eq '【更新】記事1'
      expect(doc1.released).to eq Time.zone.parse('2015-06-13T11:00:00+09:00')
      # doc2 is deleted.
      doc2 = Rss::Page.where(rss_link: "http://example.jp/rdf/2.html").first
      expect(doc2).to be_nil
      # doc6 is added
      doc6 = Rss::Page.where(rss_link: "http://example.jp/rdf/6.html").first
      expect(doc6).not_to be_nil
    end
  end
end
