require 'spec_helper'

describe Cms::ContentLinkChecker, type: :model, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node) { create :article_node_page, cur_site: site, layout: layout }

  context "with several links" do
    let(:ss_file1) { create :ss_file, site: site, user: user }
    let(:ss_file2) { create :ss_file, site: site, user: user }

    let(:success_anchor1) { unique_id }
    let(:failed_anchor1) { unique_id }

    let(:success_url1) { ss_file1.url }
    let(:success_url2) { Addressable::URI.join(site.full_url, ss_file2.url).to_s }
    let(:success_url3) { "https://success.example.jp" }
    let(:success_url4) { "https://success.example.jp/?キー=値" }

    let(:failed_url1) { "/fs/1/_/failed.txt" }
    let(:failed_url2) { Addressable::URI.join(site.full_url, "/fs/2/_/2.pdf").to_s }
    let(:failed_url3) { "https://failed.example.jp" }

    let(:invalid_url1) { "https://invalid.example.jp /" }

    before do
      WebMock.disable_net_connect!

      success_return = { body: "", status: 200, headers: { 'Content-Type' => 'text/html; charset=utf-8' } }
      Addressable::URI.join(site.full_url, success_url1).to_s.tap do |u|
        stub_request(:get, /^#{::Regexp.escape(u)}/).to_return(success_return)
      end
      stub_request(:get, /^#{::Regexp.escape(success_url2)}/).to_return(success_return)
      stub_request(:get, /^#{::Regexp.escape(success_url3)}/).to_return(success_return)
      # stub_request(:get, /^#{::Regexp.escape(success_url4)}/).to_return(success_return)
      failed_return = { body: "", status: 404, headers: { 'Content-Type' => 'text/html; charset=utf-8' } }
      Addressable::URI.join(site.full_url, failed_url1).to_s.tap do |u|
        stub_request(:get, u).to_return(failed_return)
      end
      stub_request(:get, failed_url2).to_return(failed_return)
      stub_request(:get, failed_url3).to_return(failed_return)
    end

    after do
      WebMock.reset!
      WebMock.allow_net_connect!
    end

    let(:html) do
      <<~HTML.freeze
        <a href="##{success_anchor1}">#{success_anchor1}</a>
        <a href="##{failed_anchor1}">#{failed_anchor1}</a>

        <a class="icon-png" href="#{success_url1}">#{success_url1}</a>
        <a href="#{success_url2}">#{success_url2}</a>
        <a id="#{success_anchor1}" href="#{success_url3}">#{success_url3}</a>
        <a href="#{success_url4}">#{success_url4}</a>

        <a class="icon-png" href="#{failed_url1}">#{failed_url1}</a>
        <a href="#{failed_url2}">#{failed_url2}</a>
        <a href="#{failed_url3}">#{failed_url3}</a>

        <a href="#{invalid_url1}">#{invalid_url1}</a>
      HTML
    end
    let!(:article) do
      create :article_page, cur_node: node, layout: layout, html: html, file_ids: [ss_file1.id, ss_file2.id], state: "public"
    end

    it do
      checker = Cms::ContentLinkChecker.check(cur_site: site, cur_user: user, page: article, html: html)
      expect(checker.extracted_urls.size).to eq 10
      expect(checker.results.size).to eq 10
      checker.results[checker.extracted_urls["##{success_anchor1}"]].tap do |result|
        expect(result[:code]).to eq 200
        expect(result[:message]).to be_blank
        expect(result[:normalized_url]).to eq Addressable::URI.join(article.full_url, "##{success_anchor1}").to_s
      end
      checker.results[checker.extracted_urls["##{failed_anchor1}"]].tap do |result|
        expect(result[:code]).to eq 0
        expect(result[:message]).to eq I18n.t('errors.template.no_links')
        expect(result[:normalized_url]).to eq Addressable::URI.join(article.full_url, "##{failed_anchor1}").to_s
      end
      checker.results[checker.extracted_urls[success_url1]].tap do |result|
        expect(result[:code]).to eq 200
        expect(result[:message]).to be_blank
        expect(result[:normalized_url]).to eq Addressable::URI.join(site.full_url, success_url1).to_s
      end
      checker.results[checker.extracted_urls[success_url2]].tap do |result|
        expect(result[:code]).to eq 200
        expect(result[:message]).to be_blank
        expect(result[:normalized_url]).to eq success_url2
      end
      checker.results[checker.extracted_urls[success_url3]].tap do |result|
        expect(result[:code]).to eq 200
        expect(result[:message]).to be_blank
        expect(result[:normalized_url]).to eq success_url3
      end
      checker.results[checker.extracted_urls[success_url4]].tap do |result|
        expect(result[:code]).to eq 200
        expect(result[:message]).to be_blank
        expect(result[:normalized_url]).to eq success_url4
      end
      checker.results[checker.extracted_urls[failed_url1]].tap do |result|
        expect(result[:code]).to eq 0
        expect(result[:message]).to eq I18n.t("errors.messages.link_check_failed_not_found")
        expect(result[:normalized_url]).to eq Addressable::URI.join(site.full_url, failed_url1).to_s
      end
      checker.results[checker.extracted_urls[failed_url2]].tap do |result|
        expect(result[:code]).to eq 0
        expect(result[:message]).to eq I18n.t("errors.messages.link_check_failed_not_found")
        expect(result[:normalized_url]).to eq failed_url2
      end
      checker.results[checker.extracted_urls[failed_url3]].tap do |result|
        expect(result[:code]).to eq 0
        expect(result[:message]).to eq I18n.t("errors.messages.link_check_failed_not_found")
        expect(result[:normalized_url]).to eq failed_url3
      end
      checker.results[checker.extracted_urls[invalid_url1]].tap do |result|
        expect(result[:code]).to eq 0
        expect(result[:message]).to eq I18n.t("errors.messages.link_check_failed_invalid_link")
        expect(result[:normalized_url]).to be_blank
      end
    end
  end

  context "with redirection url" do
    let(:redirection_url0) { "https://redirection-0.example.jp/" }
    let(:redirection_url1) { "http://redirection-1.example.jp/" }
    let(:redirection_url2) { "https://redirection-2.example.jp/" }
    let(:redirection_url3) { "http://redirection-3.example.jp/" }
    let(:redirection_url4) { "https://redirection-4.example.jp/" }
    let(:redirection_url5) { "http://redirection-5.example.jp/" }
    let(:redirection_self_url) { "https://redirection-self.example.jp/" }
    let(:html) do
      <<~HTML.freeze
        <a href="#{redirection_url5}">#{redirection_url5}</a>
        <a href="#{redirection_self_url}">#{redirection_self_url}</a>
      HTML
    end
    let!(:article) { create :article_page, cur_node: node, layout: layout, html: html, state: "public" }

    before do
      WebMock.disable_net_connect!

      stub_request(:get, /^#{::Regexp.escape(redirection_url0)}/)
        .to_return(body: "", status: 200, headers: { 'Content-Type' => 'text/html; charset=utf-8' })
      stub_request(:get, /^#{::Regexp.escape(redirection_url1)}/)
        .to_return(status: 302, headers: { 'Location' => redirection_url0, 'Content-Type' => 'text/html; charset=utf-8' })
      stub_request(:get, /^#{::Regexp.escape(redirection_url2)}/)
        .to_return(status: 302, headers: { 'Location' => redirection_url1, 'Content-Type' => 'text/html; charset=utf-8' })
      stub_request(:get, /^#{::Regexp.escape(redirection_url3)}/)
        .to_return(status: 302, headers: { 'Location' => redirection_url2, 'Content-Type' => 'text/html; charset=utf-8' })
      stub_request(:get, /^#{::Regexp.escape(redirection_url4)}/)
        .to_return(status: 302, headers: { 'Location' => redirection_url3, 'Content-Type' => 'text/html; charset=utf-8' })
      stub_request(:get, /^#{::Regexp.escape(redirection_url5)}/)
        .to_return(status: 302, headers: { 'Location' => redirection_url4, 'Content-Type' => 'text/html; charset=utf-8' })
      stub_request(:get, /^#{::Regexp.escape(redirection_self_url)}/)
        .to_return(status: 302, headers: { 'Location' => redirection_self_url, 'Content-Type' => 'text/html; charset=utf-8' })
    end

    after do
      WebMock.reset!
      WebMock.allow_net_connect!
    end

    it do
      checker = Cms::ContentLinkChecker.check(cur_site: site, cur_user: user, page: article, html: html)
      expect(checker.extracted_urls.size).to eq 2
      expect(checker.results.size).to eq 2
      checker.results[checker.extracted_urls[redirection_url5]].tap do |result|
        expect(result[:code]).to eq 200
        expect(result[:message]).to be_blank
        expect(result[:redirection]).to eq 5
        expect(result[:normalized_url]).to eq redirection_url5
      end
      checker.results[checker.extracted_urls[redirection_self_url]].tap do |result|
        expect(result[:code]).to eq 0
        expect(result[:message]).to eq I18n.t("errors.messages.link_check_failed_redirection")
        expect(result[:redirection]).to eq 20
        expect(result[:normalized_url]).to eq redirection_self_url
      end
    end
  end

  context "with invalid anchors" do
    let(:html) do
      <<~HTML.freeze
        <a href="#/foo/bar.baz">foo bar baz</a>
      HTML
    end
    let!(:article) { create :article_page, cur_node: node, layout: layout, html: html, state: "public" }

    before do
      WebMock.disable_net_connect!
    end

    after do
      WebMock.reset!
      WebMock.allow_net_connect!
    end

    it do
      checker = Cms::ContentLinkChecker.check(cur_site: site, cur_user: user, page: article, html: html)

      expect(checker.extracted_urls.size).to eq 1
      expect(checker.results.size).to eq 1
      checker.results[checker.extracted_urls["#/foo/bar.baz"]].tap do |result|
        expect(result[:code]).to eq 0
        expect(result[:message]).to eq I18n.t('errors.template.no_links')
        expect(result[:normalized_url]).to eq Addressable::URI.join(article.full_url, "#/foo/bar.baz").to_s
      end
    end
  end

  context "one url with different formats" do
    let(:url1) { "/#{node.filename}/page381.html" }
    let(:url2) { "./page381.html" }
    let(:url3) { "//#{site.domains.first}/#{node.filename}/page381.html" }
    let(:url4) { Addressable::URI.join(site.full_url, url1).to_s }
    let(:html) do
      <<~HTML.freeze
        <a href="#{url1}">#{url1}</a>
        <a href="#{url2}">#{url2}</a>
        <a href="#{url3}">#{url3}</a>
        <a href="#{url4}">#{url4}</a>
      HTML
    end
    let!(:article) { create :article_page, cur_node: node, layout: layout, html: html, state: "public" }

    before do
      WebMock.disable_net_connect!

      success_return = { body: "", status: 200, headers: { 'Content-Type' => 'text/html; charset=utf-8' } }
      stub_request(:get, url4).to_return(success_return)
    end

    after do
      WebMock.reset!
      WebMock.allow_net_connect!
    end

    it do
      checker = Cms::ContentLinkChecker.check(cur_site: site, cur_user: user, page: article, html: html)

      expect(checker.extracted_urls.size).to eq 4
      expect(checker.extracted_urls[url1]).to eq url4
      expect(checker.extracted_urls[url2]).to eq url4
      expect(checker.extracted_urls[url3]).to eq url4
      expect(checker.extracted_urls[url4]).to eq url4

      expect(checker.results.size).to eq 1
      checker.results[url4].tap do |result|
        expect(result[:code]).to eq 200
        expect(result[:message]).to be_blank
        expect(result[:normalized_url]).to eq url4
      end

      expect(a_request(:get, url4)).to have_been_made.times(1)
    end
  end

  context "with 'nofollow'" do
    let(:url1) { unique_url }
    let(:url2) { unique_url }
    let(:html) do
      <<~HTML.freeze
        <!-- rel は複数の値を持つ場合がある -->
        <a href="#{url1}" rel="noreferrer nofollow" data-ss-rel="">#{url1}</a>
        <!-- rel と data-ss-rel は同時に指定される場合がある -->
        <a href="#{url2}" rel="noreferrer" data-ss-rel="nofollow">#{url2}</a>
      HTML
    end
    let!(:article) { create :article_page, cur_node: node, layout: layout, html: html, state: "public" }

    before do
      WebMock.disable_net_connect!

      failed_return = { body: "", status: 404, headers: { 'Content-Type' => 'text/html; charset=utf-8' } }
      stub_request(:get, url1).to_return(failed_return)
      stub_request(:get, url2).to_return(failed_return)
    end

    after do
      WebMock.reset!
      WebMock.allow_net_connect!
    end

    it do
      checker = Cms::ContentLinkChecker.check(cur_site: site, cur_user: user, page: article, html: html)

      expect(checker.extracted_urls.size).to eq 2
      expect(checker.extracted_urls[url1]).to eq url1
      expect(checker.extracted_urls[url2]).to eq url2

      expect(checker.results.size).to eq 2
      # nofollow がセットされているので、エラーとはせず、message に "nofollow" を応答する
      checker.results[url1].tap do |result|
        expect(result[:code]).to eq "nofollow"
        expect(result[:message]).to be_blank
        expect(result[:normalized_url]).to eq url1
      end
      checker.results[url2].tap do |result|
        expect(result[:code]).to eq "nofollow"
        expect(result[:message]).to be_blank
        expect(result[:normalized_url]).to eq url2
      end

      # nofollow がセットされているので、リンクを辿らない
      expect(a_request(:get, url1)).to have_been_made.times(0)
      expect(a_request(:get, url2)).to have_been_made.times(0)
    end
  end
end
