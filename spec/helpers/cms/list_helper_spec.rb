require 'spec_helper'
require 'timecop'

describe Cms::ListHelper, type: :helper, dbscope: :example do
  let(:site) { cms_site }

  let!(:node1) do
    create :cms_node_node, cur_site: site, filename: "node1",
      index_name: "index1", summary_html: "summary1"
  end
  let!(:node2) do
    create :article_node_page, cur_site: site, filename: "node1/node2",
      index_name: "index2", summary_html: "summary2"
  end
  let!(:node3) do
    create :event_node_page, cur_site: site, filename: "node1/node3",
      index_name: "index3", summary_html: "summary3"
  end
  let!(:node4) do
    create :faq_node_page, cur_site: site, filename: "node1/node4",
      index_name: "index4", summary_html: "summary4"
  end
  let!(:node5) do
    create :rss_node_page, cur_site: site, filename: "node1/node5",
      index_name: "index5", summary_html: "summary5"
  end
  let!(:node6) do
    create :opendata_node_dataset, cur_site: site, filename: "node1/node6",
      index_name: "index6", summary_html: "summary6"
  end

  let!(:article_page) { create :article_page, cur_site: site, cur_node: node2 }
  let!(:loop_html) { ::File.read("spec/fixtures/cms/template/shirasagi/loop.html") }

  let(:node2_date) { I18n.l(node2.date.to_date) }
  let(:node2_date_default) { I18n.l(node2.date.to_date, format: :default) }
  let(:node2_date_iso) { I18n.l(node2.date.to_date, format: :iso) }
  let(:node2_date_long) { I18n.l(node2.date.to_date, format: :long) }
  let(:node2_date_short) { I18n.l(node2.date.to_date, format: :short) }

  let(:node2_time) { I18n.l(node2.date) }
  let(:node2_time_default) { I18n.l(node2.date, format: :default) }
  let(:node2_time_iso) { I18n.l(node2.date, format: :iso) }
  let(:node2_time_long) { I18n.l(node2.date, format: :long) }
  let(:node2_time_short) { I18n.l(node2.date, format: :short) }

  before do
    @cur_path = "/node1/index.html"
    @cur_site = site
    @cur_node = node1
    @items = Cms::Node.site(@cur_site).and_public.where(@cur_node.condition_hash).order_by(@cur_node.sort_hash)
  end

  context "render_node_list" do
    it "with default template" do
      html = Capybara.string(helper.render_node_list)

      expect(html.first("article.item-#{node2.basename}")).to be_truthy
      expect(html.first("a[href=\"#{node2.url}\"]", text: node2.index_name)).to be_truthy

      expect(html.first("article.item-#{node3.basename}")).to be_truthy
      expect(html.first("a[href=\"#{node3.url}\"]", text: node3.index_name)).to be_truthy

      expect(html.first("article.item-#{node4.basename}")).to be_truthy
      expect(html.first("a[href=\"#{node4.url}\"]", text: node4.index_name)).to be_truthy

      expect(html.first("article.item-#{node5.basename}")).to be_truthy
      expect(html.first("a[href=\"#{node5.url}\"]", text: node5.index_name)).to be_truthy

      expect(html.first("article.item-#{node6.basename}")).to be_truthy
      expect(html.first("a[href=\"#{node6.url}\"]", text: node6.index_name)).to be_truthy
    end

    it "with shirasagi loop template" do
      node1.loop_format = "shirasagi"
      node1.loop_html = loop_html
      node1.save!

      html = Capybara.string(helper.render_node_list)

      expect(html.has_css?(".item-#{node2.basename}")).to be_truthy
      expect(html.first(".item-#{node2.basename} .class").text).to eq node2.basename
      expect(html.first(".item-#{node2.basename} .class_categories").text).to eq ""
      expect(html.first(".item-#{node2.basename} .date").text).to eq node2_date
      expect(html.first(".item-#{node2.basename} .date-default").text).to eq node2_date_default
      expect(html.first(".item-#{node2.basename} .date-iso").text).to eq node2_date_iso
      expect(html.first(".item-#{node2.basename} .date-long").text).to eq node2_date_long
      expect(html.first(".item-#{node2.basename} .date-short").text).to eq node2_date_short
      expect(html.first(".item-#{node2.basename} .time").text).to eq node2_time
      expect(html.first(".item-#{node2.basename} .time-default").text).to eq node2_time_default
      expect(html.first(".item-#{node2.basename} .time-iso").text).to eq node2_time_iso
      expect(html.first(".item-#{node2.basename} .time-long").text).to eq node2_time_long
      expect(html.first(".item-#{node2.basename} .time-short").text).to eq node2_time_short
      expect(html.first(".item-#{node2.basename} .url").text).to eq node2.url
      expect(html.first(".item-#{node2.basename} .name").text).to eq node2.name
      expect(html.first(".item-#{node2.basename} .index_name").text).to eq node2.index_name
      expect(html.first(".item-#{node2.basename} .summary").text).to eq node2.summary
      expect(html.first(".item-#{node2.basename} .html").text).to eq ""
      expect(html.first(".item-#{node2.basename} .current").text).to eq ""
      expect(html.first(".item-#{node2.basename} .new").text).to eq "new"
      expect(html.first(".item-#{node2.basename} .id").text).to eq node2.id.to_s
      expect(html.first(".item-#{node2.basename} .group").text).to eq ""
      expect(html.first(".item-#{node2.basename} .groups").text).to eq ""
      expect(html.first(".item-#{node2.basename} .img-src").text).to eq ""
      expect(html.first(".item-#{node2.basename} .thumb-src").text).to eq ""
      expect(html.first(".item-#{node2.basename} .categories").text).to eq ""
      expect(html.first(".item-#{node2.basename} .pages-count").text).to eq "1"
      expect(html.first(".item-#{node2.basename} .event_dates").text).to eq ""
      expect(html.first(".item-#{node2.basename} .event_dates-default").text).to eq ""
      expect(html.first(".item-#{node2.basename} .event_dates-default_full").text).to eq ""
      expect(html.first(".item-#{node2.basename} .event_dates-iso").text).to eq ""
      expect(html.first(".item-#{node2.basename} .event_dates-iso_full").text).to eq ""
      expect(html.first(".item-#{node2.basename} .event_dates-long").text).to eq ""
      expect(html.first(".item-#{node2.basename} .event_dates-full").text).to eq ""
      expect(html.first(".item-#{node2.basename} .event_deadline").text).to eq ""
      expect(html.first(".item-#{node2.basename} .event_deadline-iso").text).to eq ""
      expect(html.first(".item-#{node2.basename} .event_deadline-long").text).to eq ""
      expect(html.first(".item-#{node2.basename} .event_deadline-short").text).to eq ""
      expect(html.first(".item-#{node2.basename} .tags").text).to eq ""

      expect(html.has_css?(".item-#{node3.basename}")).to be_truthy
      expect(html.first(".item-#{node3.basename} .class").text).to eq node3.basename
      expect(html.first(".item-#{node3.basename} .class_categories").text).to eq ""
      expect(html.first(".item-#{node3.basename} .url").text).to eq node3.url
      expect(html.first(".item-#{node3.basename} .name").text).to eq node3.name
      expect(html.first(".item-#{node3.basename} .index_name").text).to eq node3.index_name
      expect(html.first(".item-#{node3.basename} .summary").text).to eq node3.summary
      expect(html.first(".item-#{node3.basename} .html").text).to eq ""
      expect(html.first(".item-#{node3.basename} .current").text).to eq ""
      expect(html.first(".item-#{node3.basename} .new").text).to eq "new"
      expect(html.first(".item-#{node3.basename} .id").text).to eq node3.id.to_s
      expect(html.first(".item-#{node3.basename} .group").text).to eq ""
      expect(html.first(".item-#{node3.basename} .groups").text).to eq ""
      expect(html.first(".item-#{node3.basename} .img-src").text).to eq ""
      expect(html.first(".item-#{node3.basename} .thumb-src").text).to eq ""
      expect(html.first(".item-#{node3.basename} .categories").text).to eq ""
      expect(html.first(".item-#{node3.basename} .pages-count").text).to eq "0"
      expect(html.first(".item-#{node3.basename} .event_dates").text).to eq ""
      expect(html.first(".item-#{node3.basename} .event_dates-default").text).to eq ""
      expect(html.first(".item-#{node3.basename} .event_dates-default_full").text).to eq ""
      expect(html.first(".item-#{node3.basename} .event_dates-iso").text).to eq ""
      expect(html.first(".item-#{node3.basename} .event_dates-iso_full").text).to eq ""
      expect(html.first(".item-#{node3.basename} .event_dates-long").text).to eq ""
      expect(html.first(".item-#{node3.basename} .event_dates-full").text).to eq ""
      expect(html.first(".item-#{node3.basename} .event_deadline").text).to eq ""
      expect(html.first(".item-#{node3.basename} .event_deadline-iso").text).to eq ""
      expect(html.first(".item-#{node3.basename} .event_deadline-long").text).to eq ""
      expect(html.first(".item-#{node3.basename} .event_deadline-short").text).to eq ""
      expect(html.first(".item-#{node3.basename} .tags").text).to eq ""

      expect(html.has_css?(".item-#{node4.basename}")).to be_truthy
      expect(html.first(".item-#{node4.basename} .class").text).to eq node4.basename
      expect(html.first(".item-#{node4.basename} .class_categories").text).to eq ""
      expect(html.first(".item-#{node4.basename} .url").text).to eq node4.url
      expect(html.first(".item-#{node4.basename} .name").text).to eq node4.name
      expect(html.first(".item-#{node4.basename} .index_name").text).to eq node4.index_name
      expect(html.first(".item-#{node4.basename} .summary").text).to eq node4.summary
      expect(html.first(".item-#{node4.basename} .html").text).to eq ""
      expect(html.first(".item-#{node4.basename} .current").text).to eq ""
      expect(html.first(".item-#{node4.basename} .new").text).to eq "new"
      expect(html.first(".item-#{node4.basename} .id").text).to eq node4.id.to_s
      expect(html.first(".item-#{node4.basename} .group").text).to eq ""
      expect(html.first(".item-#{node4.basename} .groups").text).to eq ""
      expect(html.first(".item-#{node4.basename} .img-src").text).to eq ""
      expect(html.first(".item-#{node4.basename} .thumb-src").text).to eq ""
      expect(html.first(".item-#{node4.basename} .categories").text).to eq ""
      expect(html.first(".item-#{node4.basename} .pages-count").text).to eq "0"
      expect(html.first(".item-#{node4.basename} .event_dates").text).to eq ""
      expect(html.first(".item-#{node4.basename} .event_dates-default").text).to eq ""
      expect(html.first(".item-#{node4.basename} .event_dates-default_full").text).to eq ""
      expect(html.first(".item-#{node4.basename} .event_dates-iso").text).to eq ""
      expect(html.first(".item-#{node4.basename} .event_dates-iso_full").text).to eq ""
      expect(html.first(".item-#{node4.basename} .event_dates-long").text).to eq ""
      expect(html.first(".item-#{node4.basename} .event_dates-full").text).to eq ""
      expect(html.first(".item-#{node4.basename} .event_deadline").text).to eq ""
      expect(html.first(".item-#{node4.basename} .event_deadline-iso").text).to eq ""
      expect(html.first(".item-#{node4.basename} .event_deadline-long").text).to eq ""
      expect(html.first(".item-#{node4.basename} .event_deadline-short").text).to eq ""
      expect(html.first(".item-#{node4.basename} .tags").text).to eq ""

      expect(html.has_css?(".item-#{node5.basename}")).to be_truthy
      expect(html.first(".item-#{node5.basename} .class").text).to eq node5.basename
      expect(html.first(".item-#{node5.basename} .class_categories").text).to eq ""
      expect(html.first(".item-#{node5.basename} .class").text).to eq node5.basename
      expect(html.first(".item-#{node5.basename} .class_categories").text).to eq ""
      expect(html.first(".item-#{node5.basename} .url").text).to eq node5.url
      expect(html.first(".item-#{node5.basename} .name").text).to eq node5.name
      expect(html.first(".item-#{node5.basename} .index_name").text).to eq node5.index_name
      expect(html.first(".item-#{node5.basename} .summary").text).to eq node5.summary
      expect(html.first(".item-#{node5.basename} .html").text).to eq ""
      expect(html.first(".item-#{node5.basename} .current").text).to eq ""
      expect(html.first(".item-#{node5.basename} .new").text).to eq "new"
      expect(html.first(".item-#{node5.basename} .id").text).to eq node5.id.to_s
      expect(html.first(".item-#{node5.basename} .group").text).to eq ""
      expect(html.first(".item-#{node5.basename} .groups").text).to eq ""
      expect(html.first(".item-#{node5.basename} .img-src").text).to eq ""
      expect(html.first(".item-#{node5.basename} .thumb-src").text).to eq ""
      expect(html.first(".item-#{node5.basename} .categories").text).to eq ""
      expect(html.first(".item-#{node5.basename} .pages-count").text).to eq "0"
      expect(html.first(".item-#{node5.basename} .event_dates").text).to eq ""
      expect(html.first(".item-#{node5.basename} .event_dates-default").text).to eq ""
      expect(html.first(".item-#{node5.basename} .event_dates-default_full").text).to eq ""
      expect(html.first(".item-#{node5.basename} .event_dates-iso").text).to eq ""
      expect(html.first(".item-#{node5.basename} .event_dates-iso_full").text).to eq ""
      expect(html.first(".item-#{node5.basename} .event_dates-long").text).to eq ""
      expect(html.first(".item-#{node5.basename} .event_dates-full").text).to eq ""
      expect(html.first(".item-#{node5.basename} .event_deadline").text).to eq ""
      expect(html.first(".item-#{node5.basename} .event_deadline-iso").text).to eq ""
      expect(html.first(".item-#{node5.basename} .event_deadline-long").text).to eq ""
      expect(html.first(".item-#{node5.basename} .event_deadline-short").text).to eq ""
      expect(html.first(".item-#{node5.basename} .tags").text).to eq ""

      expect(html.has_css?(".item-#{node6.basename}")).to be_truthy
      expect(html.first(".item-#{node6.basename} .class").text).to eq node6.basename
      expect(html.first(".item-#{node6.basename} .class_categories").text).to eq ""
      expect(html.first(".item-#{node6.basename} .class").text).to eq node6.basename
      expect(html.first(".item-#{node6.basename} .class_categories").text).to eq ""
      expect(html.first(".item-#{node6.basename} .class").text).to eq node6.basename
      expect(html.first(".item-#{node6.basename} .class_categories").text).to eq ""
      expect(html.first(".item-#{node6.basename} .url").text).to eq node6.url
      expect(html.first(".item-#{node6.basename} .name").text).to eq node6.name
      expect(html.first(".item-#{node6.basename} .index_name").text).to eq node6.index_name
      expect(html.first(".item-#{node6.basename} .summary").text).to eq node6.summary
      expect(html.first(".item-#{node6.basename} .html").text).to eq ""
      expect(html.first(".item-#{node6.basename} .current").text).to eq ""
      expect(html.first(".item-#{node6.basename} .new").text).to eq "new"
      expect(html.first(".item-#{node6.basename} .id").text).to eq node6.id.to_s
      expect(html.first(".item-#{node6.basename} .group").text).to eq ""
      expect(html.first(".item-#{node6.basename} .groups").text).to eq ""
      expect(html.first(".item-#{node6.basename} .img-src").text).to eq ""
      expect(html.first(".item-#{node6.basename} .thumb-src").text).to eq ""
      expect(html.first(".item-#{node6.basename} .categories").text).to eq ""
      expect(html.first(".item-#{node6.basename} .pages-count").text).to eq "0"
      expect(html.first(".item-#{node6.basename} .event_dates").text).to eq ""
      expect(html.first(".item-#{node6.basename} .event_dates-default").text).to eq ""
      expect(html.first(".item-#{node6.basename} .event_dates-default_full").text).to eq ""
      expect(html.first(".item-#{node6.basename} .event_dates-iso").text).to eq ""
      expect(html.first(".item-#{node6.basename} .event_dates-iso_full").text).to eq ""
      expect(html.first(".item-#{node6.basename} .event_dates-long").text).to eq ""
      expect(html.first(".item-#{node6.basename} .event_dates-full").text).to eq ""
      expect(html.first(".item-#{node6.basename} .event_deadline").text).to eq ""
      expect(html.first(".item-#{node6.basename} .event_deadline-iso").text).to eq ""
      expect(html.first(".item-#{node6.basename} .event_deadline-long").text).to eq ""
      expect(html.first(".item-#{node6.basename} .event_deadline-short").text).to eq ""
      expect(html.first(".item-#{node6.basename} .tags").text).to eq ""
    end
  end
end
