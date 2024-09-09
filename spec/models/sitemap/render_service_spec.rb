require 'spec_helper'

describe Sitemap::RenderService do
  context "initial setting" do
    let!(:node) { create :sitemap_node_page }
    let!(:item) { create :sitemap_page, cur_node: node }
    subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

    it { expect(subject.load_whole_contents.map(&:url)).to include(node.url) }
    # it { expect(item.load_sitemap_urls(name: true)).to include("#{node.url} ##{node.name}") }
  end

  context 'when sitemap_page_state is hide' do
    let!(:article_node) { create :article_node_page }
    let!(:cms_page) { create :cms_page, cur_node: article_node, basename: "index.html" }
    let!(:article_page) { create :article_page, cur_node: article_node }
    let!(:node) { create :sitemap_node_page }
    let!(:item) { create :sitemap_page, cur_node: node, sitemap_page_state: 'hide' }
    subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

    it { expect(subject.load_whole_contents.map(&:url)).to include(article_node.url) }
    it { expect(subject.load_whole_contents.map(&:url)).not_to include(cms_page.url) }
    it { expect(subject.load_whole_contents.map(&:url)).not_to include(article_page.url) }
    # it { expect(item.load_sitemap_urls(name: true)).to include("#{article_node.url} ##{article_node.name}") }
    # it { expect(item.load_sitemap_urls(name: true)).not_to include("#{article_page.url} ##{article_page.name}") }
  end

  context 'when sitemap_page_state is show' do
    let!(:article_node) { create :article_node_page }
    let!(:cms_page) { create :cms_page, cur_node: article_node, basename: "index.html" }
    let!(:article_page) { create :article_page, cur_node: article_node }
    let!(:node) { create :sitemap_node_page }
    let!(:item) { create :sitemap_page, cur_node: node, sitemap_page_state: 'show' }
    subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

    it { expect(subject.load_whole_contents.map(&:url)).to include(article_node.url) }
    # index.htmlは含まれない（なお、理由は不明）
    it { expect(subject.load_whole_contents.map(&:url)).not_to include(cms_page.url) }
    it { expect(subject.load_whole_contents.map(&:url)).to include(article_page.url) }
    # it { expect(item.load_sitemap_urls(name: true)).to include("#{article_node.url} ##{article_node.name}") }
    # it { expect(item.load_sitemap_urls(name: true)).to include("#{article_page.url} ##{article_page.name}") }
  end

  context "sitemap/addon/body#sitemap_deny_urls" do
    context 'tooltip #1: 前方一致したURLを除外します' do
      let!(:article_node) { create :article_node_page }
      let!(:article_page1) { create :article_page, cur_node: article_node }
      let!(:article_page2) { create :article_page, cur_node: article_node }
      let!(:node) { create :sitemap_node_page }
      let!(:item) do
        create :sitemap_page, cur_node: node, sitemap_page_state: 'show', sitemap_deny_urls: [ article_node.url ]
      end
      subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

      it do
        expect(subject.load_whole_contents.map(&:url)).not_to include(article_node.url)
        expect(subject.load_whole_contents.map(&:url)).not_to include(article_page1.url)
        expect(subject.load_whole_contents.map(&:url)).not_to include(article_page2.url)
      end
    end

    context 'tooltip #2: docs/archiveフォルダー以下すべてを除外' do
      let!(:article_node) { create :article_node_page }
      let!(:archive_node) { create :cms_node_archive, cur_node: article_node }
      let!(:cms_page1) { create :cms_page, cur_node: article_node, basename: "index.html" }
      let!(:article_page1) { create :article_page, cur_node: article_node }
      let!(:article_page2) { create :article_page, cur_node: article_node }
      let!(:node) { create :sitemap_node_page }
      let!(:item) do
        create :sitemap_page, cur_node: node, sitemap_page_state: 'show', sitemap_deny_urls: [ archive_node.url ]
      end
      subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

      it do
        expect(subject.load_whole_contents.map(&:url)).not_to include(cms_page1.url)
        expect(subject.load_whole_contents.map(&:url)).to include(article_page1.url)
        expect(subject.load_whole_contents.map(&:url)).to include(article_page2.url)
        expect(subject.load_whole_contents.map(&:url)).not_to include(archive_node.url)
      end
    end

    context 'tooltip #3: ページのURLを指定して除外' do
      let!(:article_node) { create :article_node_page }
      let!(:article_page1) { create :article_page, cur_node: article_node }
      let!(:article_page2) { create :article_page, cur_node: article_node }
      let!(:node) { create :sitemap_node_page }
      let!(:item) do
        create :sitemap_page, cur_node: node, sitemap_page_state: 'show', sitemap_deny_urls: [ article_page2.url ]
      end
      subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

      it do
        expect(subject.load_whole_contents.map(&:url)).to include(article_page1.url)
        expect(subject.load_whole_contents.map(&:url)).not_to include(article_page2.url)
      end
    end
  end
end
