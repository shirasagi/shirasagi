require 'spec_helper'

describe Rss::Page, dbscope: :example do
  describe "basic attributes" do
    let(:site) { cms_site }
    let(:node) { create :rss_node_page, site: site }
    subject { create :rss_page, site: site, node: node }

    its(:becomes_with_route) { is_expected.not_to be_nil }
    its(:parent) { expect(subject.parent.id).to eq node.id }
    its(:dirname) { is_expected.to eq node.filename }
    its(:basename) { is_expected.not_to be_nil }
    its(:path) { is_expected.not_to be_nil }
    its(:url) { is_expected.not_to be_nil }
    its(:full_url) { is_expected.not_to be_nil }
    its(:json_path) { is_expected.to be_nil }
    its(:json_url) { is_expected.to be_nil }
    its(:serve_static_file?) { is_expected.to be_falsey }
  end
end
