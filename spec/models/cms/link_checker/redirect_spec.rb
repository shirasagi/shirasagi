require 'spec_helper'

describe Cms::LinkChecker, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:site) { create :cms_site_subdir, parent: site0 }
  let(:ip_address) { "10.11.102.8" }
  let!(:checker) { Cms::LinkChecker.new(root_url: site.full_url, fetch_content: true) }

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

  context "when http external site responds a typical redirection" do
    let(:url0) { "http://#{unique_domain}/#{unique_id}/" }
    let(:url1) { "http://#{unique_domain}/#{unique_id}/" }

    before do
      # HTTP の場合は証明書の検証が不要なので、URLのホスト部分がIPアドレスに差し変わる
      Addressable::URI.parse(url0).tap do |orig_uri|
        access_uri = orig_uri.dup
        access_uri.host = ip_address
        stub_request(:head, access_uri.to_s)
          .with(headers: { "Host" => orig_uri.host })
          .to_return(status: 302, body: "", headers: { 'Location' => url1 })
      end
      Addressable::URI.parse(url1).tap do |orig_uri|
        access_uri = orig_uri.dup
        access_uri.host = ip_address
        stub_request(:head, access_uri.to_s)
          .with(headers: { "Host" => orig_uri.host })
          .to_return(status: 200, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
      end
    end

    it do
      result = checker.check_url(url0)
      expect(result.success?).to be_truthy
      expect(result.result).to eq :success
      expect(result.error_code).to be_blank
      expect(result.redirection_count).to eq 1
      expect(result.content_type).to eq "text/html; charset=utf-8"
      expect(result.content).to be_blank
    end
  end

  context "when https external site responds a typical redirection" do
    let(:url0) { "https://#{unique_domain}/#{unique_id}/" }
    let(:url1) { "https://#{unique_domain}/#{unique_id}/" }

    before do
      # HTTPS の場合は証明書の検証が必要なので、URLのホスト部分はもとのまま
      stub_request(:head, url0)
        .to_return(status: 302, body: "", headers: { 'Location' => url1 })
      stub_request(:head, url1)
        .to_return(status: 200, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    it do
      result = checker.check_url(url0)
      expect(result.success?).to be_truthy
      expect(result.result).to eq :success
      expect(result.error_code).to be_blank
      expect(result.redirection_count).to eq 1
      expect(result.content_type).to eq "text/html; charset=utf-8"
      expect(result.content).to be_blank
    end
  end

  context "when external site responds a cyclic redirection #1" do
    let(:url0) { "https://#{unique_domain}/#{unique_id}/" }

    before do
      stub_request(:head, url0)
        .to_return(status: 302, body: "", headers: { 'Location' => url0 })
    end

    it do
      result = checker.check_url(url0)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_cyclic_redirection
      expect(result.redirection_count).to eq 1
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end

  context "when external site responds a cyclic redirection #2" do
    let(:url0) { "https://#{unique_domain}/#{unique_id}/" }
    let(:url1) { "https://#{unique_domain}/#{unique_id}/" }

    before do
      stub_request(:head, url0)
        .to_return(status: 302, body: "", headers: { 'Location' => url1 })
      stub_request(:head, url1)
        .to_return(status: 302, body: "", headers: { 'Location' => url0 })
    end

    it do
      result = checker.check_url(url0)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_cyclic_redirection
      expect(result.redirection_count).to eq 2
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end

  context "when external site responds many redirections #1" do
    let(:url0) { "https://#{unique_domain}/#{unique_id}/" }
    let(:url1) { "https://#{unique_domain}/#{unique_id}/" }
    let(:url2) { "https://#{unique_domain}/#{unique_id}/" }
    let(:url3) { "https://#{unique_domain}/#{unique_id}/" }
    let(:url4) { "https://#{unique_domain}/#{unique_id}/" }
    let(:url5) { "https://#{unique_domain}/#{unique_id}/" }
    let(:url6) { "https://#{unique_domain}/#{unique_id}/" }

    before do
      checker.instance_variable_set(:@max_redirection, 5)

      stub_request(:head, url0)
        .to_return(status: 302, body: "", headers: { 'Location' => url1 })
      stub_request(:head, url1)
        .to_return(status: 302, body: "", headers: { 'Location' => url2 })
      stub_request(:head, url2)
        .to_return(status: 302, body: "", headers: { 'Location' => url3 })
      stub_request(:head, url3)
        .to_return(status: 302, body: "", headers: { 'Location' => url4 })
      stub_request(:head, url4)
        .to_return(status: 302, body: "", headers: { 'Location' => url5 })
      stub_request(:head, url5)
        .to_return(status: 302, body: "", headers: { 'Location' => url6 })
      stub_request(:head, url6)
        .to_return(status: 200, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    it do
      result = checker.check_url(url0)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_redirection
      expect(result.redirection_count).to eq 6
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end
end
