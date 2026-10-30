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

  context "when IPv4 loopback address is given" do
    let(:url) { "https://127.0.0.1/" }

    before do
      stub_request(:head, url)
        .to_return(status: 200, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    it do
      result = checker.check_url(url)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_not_found
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end

  context "when IPv6 loopback address is given" do
    let(:url) { "https://[::1]/" }

    before do
      stub_request(:head, url)
        .to_return(status: 200, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    it do
      result = checker.check_url(url)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_not_found
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end

  context "when IPv4 private address is given" do
    let(:url) { "https://172.16.1.1/" }

    before do
      stub_request(:head, url)
        .to_return(status: 200, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    it do
      result = checker.check_url(url)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_not_found
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end

  context "when IPv6 unique local address is given" do
    let(:url) { "https://[fc00::1]/" }

    before do
      stub_request(:head, url)
        .to_return(status: 200, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    it do
      result = checker.check_url(url)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_not_found
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end

  context "when IPv4 link-local address is given" do
    let(:url) { "https://169.254.1.1/" }

    before do
      stub_request(:head, url)
        .to_return(status: 200, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    it do
      result = checker.check_url(url)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_not_found
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end

  context "when IPv6 link-local address is given" do
    let(:url) { "https://[fe80::1]/" }

    before do
      stub_request(:head, url)
        .to_return(status: 200, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    it do
      result = checker.check_url(url)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_not_found
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end

  context "when IPv4 meta address is given" do
    let(:url) { "https://0.0.0.0/" }

    before do
      stub_request(:head, url)
        .to_return(status: 200, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    it do
      result = checker.check_url(url)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_not_found
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end

  context "when IPv4 limited broadcast address is given" do
    let(:url) { "https://255.255.255.255/" }

    before do
      stub_request(:head, url)
        .to_return(status: 200, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    it do
      result = checker.check_url(url)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_not_found
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end
end
