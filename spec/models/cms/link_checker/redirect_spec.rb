require 'spec_helper'

describe Cms::LinkChecker, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:site) { create :cms_site_subdir, parent: site0 }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
    Fs.rm_rf site0.path
  end

  after do
    Fs.rm_rf site0.path
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  context "when external site responds a typical redirection" do
    let(:url0) { unique_url }
    let(:url1) { unique_url }

    before do
      stub_request(:head, url0)
        .to_return(status: 302, body: "", headers: { 'Location' => url1 })
      stub_request(:head, url1)
        .to_return(status: 200, body: "", headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    it do
      checker = Cms::LinkChecker.new(root_url: site.full_url, fetch_content: true)
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
    let(:url0) { unique_url }

    before do
      stub_request(:head, url0)
        .to_return(status: 302, body: "", headers: { 'Location' => url0 })
    end

    it do
      checker = Cms::LinkChecker.new(root_url: site.full_url, fetch_content: true)
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
    let(:url0) { unique_url }
    let(:url1) { unique_url }

    before do
      stub_request(:head, url0)
        .to_return(status: 302, body: "", headers: { 'Location' => url1 })
      stub_request(:head, url1)
        .to_return(status: 302, body: "", headers: { 'Location' => url0 })
    end

    it do
      checker = Cms::LinkChecker.new(root_url: site.full_url, fetch_content: true)
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
    let(:url0) { unique_url }
    let(:url1) { unique_url }
    let(:url2) { unique_url }
    let(:url3) { unique_url }
    let(:url4) { unique_url }
    let(:url5) { unique_url }
    let(:url6) { unique_url }

    before do
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
      checker = Cms::LinkChecker.new(root_url: site.full_url, fetch_content: true)
      checker.instance_variable_set(:@max_redirection, 5)
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
