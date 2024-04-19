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
    let!(:article_page) { create :article_page, cur_node: article_node }
    let!(:node) { create :sitemap_node_page }
    let!(:item) { create :sitemap_page, cur_node: node, sitemap_page_state: 'hide' }
    subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

    it { expect(subject.load_whole_contents.map(&:url)).to include(article_node.url) }
    it { expect(subject.load_whole_contents.map(&:url)).not_to include(article_page.url) }
    # it { expect(item.load_sitemap_urls(name: true)).to include("#{article_node.url} ##{article_node.name}") }
    # it { expect(item.load_sitemap_urls(name: true)).not_to include("#{article_page.url} ##{article_page.name}") }
  end

  context 'when sitemap_page_state is show' do
    let!(:article_node) { create :article_node_page }
    let!(:article_page) { create :article_page, cur_node: article_node }
    let!(:node) { create :sitemap_node_page }
    let!(:item) { create :sitemap_page, cur_node: node, sitemap_page_state: 'show' }
    subject! { Sitemap::RenderService.new(cur_site: cms_site, cur_node: node, page: item) }

    it { expect(subject.load_whole_contents.map(&:url)).to include(article_node.url) }
    it { expect(subject.load_whole_contents.map(&:url)).to include(article_page.url) }
    # it { expect(item.load_sitemap_urls(name: true)).to include("#{article_node.url} ##{article_node.name}") }
    # it { expect(item.load_sitemap_urls(name: true)).to include("#{article_page.url} ##{article_page.name}") }
  end
end
