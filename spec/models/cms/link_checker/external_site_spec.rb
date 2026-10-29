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

  context "when external site is given" do
    let(:url) { "https://#{unique_domain}/#{unique_id}/" }

    before do
      stub_request(:head, url)
        .to_return(status: http_status, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    context "when external site responds 200" do
      let(:http_status) { 200 }

      it do
        result = checker.check_url(url)
        expect(result.success?).to be_truthy
        expect(result.result).to eq :success
        expect(result.error_code).to be_blank
        expect(result.redirection_count).to eq 0
        expect(result.content_type).to eq "text/html; charset=utf-8"
        expect(result.content).to be_blank
      end
    end

    context "when external site responds 400" do
      let(:http_status) { 400 }

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

    context "when external site responds 500" do
      let(:http_status) { 500 }

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

  context "when external site is timed out" do
    let(:url) { "https://#{unique_domain}/#{unique_id}/" }

    before do
      stub_request(:head, url).to_raise(Timeout::Error)
    end

    it do
      result = checker.check_url(url)
      expect(result.success?).to be_falsey
      expect(result.result).to eq :error
      expect(result.error_code).to eq :link_check_failed_timeout
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to be_blank
      expect(result.content).to be_blank
    end
  end
end
