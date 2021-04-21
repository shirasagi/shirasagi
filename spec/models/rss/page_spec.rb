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

  describe ".and_public" do
    let(:current) { Time.zone.now.beginning_of_minute }
    let!(:page1) { create :rss_page, site: site, node: node, released: current, state: "public" }
    let!(:page2) { create :rss_page, site: site, node: node, released: current, state: "closed" }
    let!(:page3) { create :rss_page, site: site, node: node, released: current + 1.day, state: "public" }
    let!(:page4) { create :rss_page, site: site, node: node, released: current + 1.day, state: "closed" }

    it do
      # without specific date to and_public
      expect(described_class.and_public.count).to eq 2
      expect(described_class.and_public.pluck(:id)).to include(page1.id, page3.id)
      expect(Cms::Page.and_public.count).to eq 2
      expect(Cms::Page.and_public.pluck(:id)).to include(page1.id, page3.id)

      # at current
      expect(described_class.and_public(current).count).to eq 1
      expect(described_class.and_public(current).pluck(:id)).to include(page1.id)
      expect(Cms::Page.and_public(current).count).to eq 1
      expect(Cms::Page.and_public(current).pluck(:id)).to include(page1.id)

      # at current + 1.day
      expect(described_class.and_public(current + 1.day).count).to eq 2
      expect(described_class.and_public(current + 1.day).pluck(:id)).to include(page1.id, page3.id)
      expect(Cms::Page.and_public(current + 1.day).count).to eq 2
      expect(Cms::Page.and_public(current + 1.day).pluck(:id)).to include(page1.id, page3.id)
    end
  end

  describe "#public?" do
    let(:current) { Time.zone.now.beginning_of_minute }
    let!(:page1) { create :rss_page, site: site, node: node, released: current, state: "public" }
    let!(:page2) { create :rss_page, site: site, node: node, released: current, state: "closed" }
    let!(:page3) { create :rss_page, site: site, node: node, released: current + 1.day, state: "public" }
    let!(:page4) { create :rss_page, site: site, node: node, released: current + 1.day, state: "closed" }

    it do
      expect(page1.public?).to be_truthy
      expect(page2.public?).to be_falsey
      expect(page3.public?).to be_truthy
      expect(page4.public?).to be_falsey

      # at current
      Timecop.freeze(current) do
        page1.reload
        page2.reload
        page3.reload
        page4.reload

        expect(page1.public?).to be_truthy
        expect(page2.public?).to be_falsey
        expect(page3.public?).to be_truthy
        expect(page4.public?).to be_falsey
      end

      # at current + 1.day
      Timecop.freeze(current + 1.day) do
        page1.reload
        page2.reload
        page3.reload
        page4.reload

        expect(page1.public?).to be_truthy
        expect(page2.public?).to be_falsey
        expect(page3.public?).to be_truthy
        expect(page4.public?).to be_falsey
      end
    end
  end
end
