require 'spec_helper'

describe Cms::LinkChecker, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:site) { create :cms_site_subdir, parent: site0 }
  let(:ip_address) { "10.11.102.8" }
  let!(:checker) { Cms::LinkChecker.new(cur_site: site, root_url: site.full_url, fetch_content: true) }

  before do
    @save_ssrf_resolver = Cms::LinkChecker.ssrf_resolver
    Cms::LinkChecker.ssrf_resolver = ->(_hostname) { [ ip_address ] }

    WebMock.disable_net_connect!(allow_localhost: true)
    Fs.rm_rf site0.path
  end

  after do
    Fs.rm_rf site0.path
    WebMock.reset!
    WebMock.allow_net_connect!

    Cms::LinkChecker.ssrf_resolver = @save_ssrf_resolver
  end

  context "when external site is ignored" do
    let(:url) { "https://#{unique_domain}/#{unique_id}/" }
    let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: url }

    before do
      stub_request(:head, url)
        .to_return(status: http_status, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    context "when external site responds 200" do
      let(:http_status) { 200 }

      it do
        result = checker.check_url(url)
        expect(result.success?).to be_falsey
        expect(result.result).to eq :error
        expect(result.error_code).to eq :link_check_failed_ignored
        expect(result.message).to be_present
        expect(result.message).not_to include "Translation missing"
        expect(result.redirection_count).to eq 0
        expect(result.content_type).to be_blank
        expect(result.content).to be_blank
      end
    end
  end

  context "when redirection destination is ignored" do
    let(:url0) { "http://#{unique_domain}/#{unique_id}/" }
    let(:url1) { "http://#{unique_domain}/#{unique_id}/" }
    let!(:ignore_url) { create :check_links_ignore_url, site: site, kind: 'all', name: url1 }

    before do
      Addressable::URI.parse(url0).tap do |orig_uri|
        access_uri = orig_uri.dup
        access_uri.host = ip_address
        stub_request(:head, access_uri.to_s)
          .with(headers: { "Host" => orig_uri.host })
          .to_return(status: 302, body: "", headers: { 'Location' => url1 })
      end
    end

    it do
      result = checker.check_url(url0)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_ignored
      expect(result.message).to be_present
      expect(result.message).not_to include "Translation missing"
      expect(result.redirection_count).to eq 1
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end
end
