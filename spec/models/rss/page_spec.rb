require 'spec_helper'

describe Rss::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :rss_node_page, site: site }

  describe "basic attributes" do
    let(:show_path) { Rails.application.routes.url_helpers.rss_page_path(site: subject.site, cid: subject.parent, id: subject) }
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
    its(:private_show_path) { is_expected.to eq show_path }
  end

  describe "validation" do
    it "rss_link" do
      item = build(:rss_page_rss_link_blank)
      expect(item).to have(1).errors_on(:rss_link)
    end
  end

  describe "serve_static_file?" do
    subject { create :rss_page, site: site, node: node }
    its(:serve_static_file?) { is_expected.to be_falsey }
  end

  describe "url and full_url" do
    context "with rss_link is given" do
      subject { create :rss_page, site: site, node: node }

      its(:url) { is_expected.to eq subject.rss_link }
      its(:full_url) { is_expected.to eq subject.rss_link }
    end

    context "with rss_link is blank" do
      subject { create :rss_page, site: site, node: node }

      before do
        # v1.12.0 より古いバージョンでは rss_link が blank になりうる
        subject.set(rss_link: nil)
      end

      its(:url) { is_expected.to eq Cms::Page.find(subject.id).url }
      its(:full_url) { is_expected.to eq Cms::Page.find(subject.id).full_url }
    end
  end
end
