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

  context "when ldaps is given" do
    let(:url) { "ldaps://#{unique_domain}/#{unique_id}/" }

    it do
      result = checker.check_url(url)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_ignored
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end

  context "when ssh is given" do
    let(:url) { "ssh://#{unique_domain}/#{unique_id}/" }

    it do
      result = checker.check_url(url)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_ignored
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end

  context "when the redirect destination is ftp" do
    let(:url0) { "https://#{unique_domain}/#{unique_id}/" }
    let(:url1) { "ftp://#{unique_domain}/#{unique_id}/" }

    before do
      stub_request(:head, url0)
        .to_return(status: 302, body: "", headers: { 'Location' => url1 })
    end

    it do
      result = checker.check_url(url0)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_not_found
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end
end
