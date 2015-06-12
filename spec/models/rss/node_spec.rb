require 'spec_helper'

describe Rss::Node::Page, dbscope: :example do
  describe "basic attributes" do
    let(:site) { cms_site }
    subject { create :rss_node_page, site: site }

    its(:becomes_with_route) { is_expected.not_to be_nil }
    its(:basename) { is_expected.not_to be_nil }
    its(:path) { is_expected.not_to be_nil }
    its(:url) { is_expected.not_to be_nil }
    its(:full_url) { is_expected.not_to be_nil }
    its(:rss_refresh_method_options) { is_expected.not_to be_nil }
  end

  describe "decrease rss_max_docs" do
    let(:site) { cms_site }
    subject { create :rss_node_page, site: site }

    before do
      create_list(:rss_page, subject.rss_max_docs, site: site, node: subject)
    end

    it do
      save = subject.rss_max_docs
      expectation = expect do
        subject.rss_max_docs -= 1
        subject.save
      end
      expectation.to change { Rss::Page.count }.from(save).to(save - 1)
    end
  end
end
