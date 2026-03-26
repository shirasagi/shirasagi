require 'spec_helper'

describe Cms::CheckLinks::LinkExtractor, type: :model, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:site) { create :cms_site_unique, domains: %w(ss1.example.jp ss2.example.jp) }

  before do
    Fs.rm_rf site.path
  end

  context "with anchor" do
    it do
      html = <<~HTML
        <a href="#anchor">Anchor</a>
        <a href="#">My Self</a>
      HTML

      extractor = described_class.new(cur_site: site, base_url: site.full_url, html: html)
      links = extractor.to_a
      expect(links).to have(1).items

      links[0].tap do |link|
        expect(link.full_url).to be_a(Addressable::URI)
        expect(link.full_url).to eq Addressable::URI.parse("#{site.full_url}#anchor")
        expect(link.href).to eq "#anchor"
        expect(link.line).to eq 1
        expect(link.type).to eq :outer_yield
        expect(link.rel).to be_blank
        expect(link.ss_rel).to be_blank
      end
    end
  end

  context "with invalid url" do
    it do
      html = <<~HTML
        <a href="https://invalid.example.jp /">Invalid URL</a>
      HTML

      extractor = described_class.new(cur_site: site, base_url: site.full_url, html: html)
      links = extractor.to_a
      expect(links).to have(1).items

      links[0].tap do |link|
        expect(link.full_url).to be_blank
        expect(link.href).to eq "https://invalid.example.jp /"
        expect(link.line).to eq 1
        expect(link.type).to eq :broken
        expect(link.rel).to be_blank
        expect(link.ss_rel).to be_blank
      end
    end
  end

  context "with javascript:" do
    it do
      html = <<~HTML
        <a href="javascript:void(0);">Nop</a>
      HTML

      extractor = described_class.new(cur_site: site, base_url: site.full_url, html: html)
      links = extractor.to_a
      expect(links).to have(1).items

      links[0].tap do |link|
        expect(link.full_url).to be_a(Addressable::URI)
        expect(link.full_url).to eq Addressable::URI.parse("javascript:void(0);")
        expect(link.href).to eq "javascript:void(0);"
        expect(link.line).to eq 1
        expect(link.type).to eq :ignore
        expect(link.rel).to be_blank
        expect(link.ss_rel).to be_blank
      end
    end
  end

  context "with /assets/cms/public.css" do
    it do
      html = <<~HTML
        <link rel="stylesheet" href="/assets/cms/public.css" media="all" />
      HTML

      extractor = described_class.new(cur_site: site, base_url: site.full_url, html: html)
      links = extractor.to_a
      expect(links).to have(1).items

      links[0].tap do |link|
        expect(link.full_url).to be_a(Addressable::URI)
        expect(link.full_url).to eq Addressable::URI.join(site.full_url, "/assets/cms/public.css")
        expect(link.href).to eq "/assets/cms/public.css"
        expect(link.line).to eq 1
        expect(link.type).to eq :ignore
        expect(link.rel).to eq "stylesheet"
        expect(link.ss_rel).to be_blank
      end
    end
  end

  context "with node 'event/page'" do
    let(:today) { Time.zone.today }
    let!(:layout) { create_cms_layout cur_site: site }
    let!(:node) { create :event_node_page, cur_site: site, layout: layout, state: "public" }
    let!(:page1) do
      event_recurrences = [ { kind: "date", start_at: today, frequency: "daily", until_on: today } ]
      create(
        :event_page, cur_site: site, cur_node: node, layout: layout, state: "public",
        event_recurrences: event_recurrences)
    end

    before do
      expect { ss_perform_now Cms::Node::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      expect { ss_perform_now Cms::Page::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      Job::Log.destroy_all
    end

    it do
      index_path = File.join(node.path, "index.html")
      html = File.read(index_path)

      extractor = described_class.new(cur_site: site, base_url: node.full_url, html: html)
      links = extractor.to_a
      puts links.map(&:href).join("\n")
      expect(links).to have(8).items

      links[0].tap do |link|
        expect(link.full_url).to be_a(Addressable::URI)
        expect(link.href).to start_with("/assets")
        expect(link.line).to be > 0
        expect(link.type).to eq :ignore
        expect(link.rel).to eq "stylesheet"
        expect(link.ss_rel).to be_blank
      end
      links[1].tap do |link|
        expect(link.full_url).to be_a(Addressable::URI)
        expect(link.href).to start_with("/assets")
        expect(link.line).to be > 0
        expect(link.type).to eq :ignore
        expect(link.rel).to eq "stylesheet"
        expect(link.ss_rel).to be_blank
      end
      links[2].tap do |link|
        path = "#{today.strftime("%Y%m")}/list.html"
        expect(link.full_url).to eq Addressable::URI.parse("#{node.full_url}#{path}")
        expect(link.href).to eq "#{node.url}#{path}"
        expect(link.line).to be > 30
        expect(link.type).to eq :inner_yield
        expect(link.rel).to be_blank
        expect(link.ss_rel).to be_blank
      end
      links[3].tap do |link|
        path = "#{today.strftime("%Y%m")}/list.ics"
        expect(link.full_url).to eq Addressable::URI.parse("#{node.full_url}#{path}")
        expect(link.href).to eq "#{node.url}#{path}"
        expect(link.line).to be > 30
        expect(link.type).to eq :inner_yield
        expect(link.rel).to be_blank
        expect(link.ss_rel).to be_blank
      end
      links[4].tap do |link|
        path = "#{today.prev_month.strftime("%Y%m")}/index.html"
        expect(link.full_url).to eq Addressable::URI.parse("#{node.full_url}#{path}")
        expect(link.href).to eq "#{node.url}#{path}"
        expect(link.line).to be > 30
        expect(link.type).to eq :inner_yield
        expect(link.rel).to be_blank
        expect(link.ss_rel).to be_blank
      end
      links[5].tap do |link|
        path = "#{today.next_month.strftime("%Y%m")}/index.html"
        expect(link.full_url).to eq Addressable::URI.parse("#{node.full_url}#{path}")
        expect(link.href).to eq "#{node.url}#{path}"
        expect(link.line).to be > 30
        expect(link.type).to eq :inner_yield
        expect(link.rel).to be_blank
        expect(link.ss_rel).to be_blank
      end
      links[6].tap do |link|
        path = "#{today.strftime("%Y%m%d")}/"
        expect(link.full_url).to eq Addressable::URI.parse("#{node.full_url}#{path}")
        expect(link.href).to eq "#{node.url}#{path}"
        expect(link.line).to be > 30
        expect(link.type).to eq :inner_yield
        expect(link.rel).to be_blank
        expect(link.ss_rel).to be_blank
      end
    end
  end
end
