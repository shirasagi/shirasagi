require 'spec_helper'

RSpec.describe Ckan::Node, type: :model, dbscope: :example do
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
end
