require 'spec_helper'

RSpec.describe Ckan::Node::Page, type: :model, dbscope: :example do
  describe "validation" do
    subject { @page.valid? }

    before { @page = build :ckan_node_page }
    it { is_expected.to be_truthy }

    describe "ckan_url" do
      context "valid format http" do
        before { @page.ckan_url = 'http://example.com' }
        it { is_expected.to be_truthy }
      end

      context "valid format https" do
        before { @page.ckan_url = 'https://example.com' }
        it { is_expected.to be_truthy }
      end

      context "invalid format" do
        before { @page.ckan_url = 'ftp://example.com' }
        it { is_expected.to be_falsy }
      end
    end

    describe "ckan_max_docs" do
      context "0" do
        before { @page.ckan_max_docs = 0 }
        it { is_expected.to be_truthy }
      end

      context "-1" do
        before { @page.ckan_max_docs = -1 }
        it { is_expected.to be_falsy }
      end
    end
  end

  describe "#values" do
    before(:all) { WebMock.enable! }

    let(:page) { build :ckan_node_page }

    before do
      stub_request(:get, "#{page.ckan_url}/api/3/action/package_search?rows=10&sort=metadata_modified%20desc").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => status, :body => body, :headers => {})
    end

    subject { page.values }

    context "ok" do
      let(:status) { 200 }
      let(:body) { "{\"success\":true,\"result\":{\"results\":[1,2,3,4,5]}}" }
      it { is_expected.to eq [1, 2, 3, 4, 5] }
    end

    context "HTTP error" do
      let(:status) { 500 }
      let(:body) { "" }
      it { is_expected.to eq [] }
    end

    context "failure" do
      let(:status) { 200 }
      let(:body) { "{\"success\":false}" }
      it { is_expected.to eq [] }
    end

    after(:all) { WebMock.disable! }
  end
end
