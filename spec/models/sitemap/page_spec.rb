require 'spec_helper'

describe Sitemap::Page do
  subject(:model) { described_class }
  subject(:factory) { :sitemap_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    let(:node) { create :sitemap_node_page }
    let(:item) { create :sitemap_page, cur_node: node }
    let(:show_path) { Rails.application.routes.url_helpers.sitemap_page_path(site: item.site, cid: node, id: item.id) }

    it { expect(item.dirname).to eq node.filename }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.parent).to eq node }
    it { expect(item.private_show_path).to eq show_path }
    it { expect(item.load_sitemap_urls).to include(node.url) }
    it { expect(item.load_sitemap_urls(name: true)).to include("#{node.url} ##{node.name}") }

    context 'when sitemap_page_state is hide' do
      let(:item) { create :sitemap_page, cur_node: node, sitemap_page_state: 'hide' }
      let(:article_node) { create :article_node_page }
      let!(:article_page) { create :article_page, cur_node: article_node }

      it { expect(item.load_sitemap_urls).to include(article_node.url) }
      it { expect(item.load_sitemap_urls).not_to include(article_page.url) }
      it { expect(item.load_sitemap_urls(name: true)).to include("#{article_node.url} ##{article_node.name}") }
      it { expect(item.load_sitemap_urls(name: true)).not_to include("#{article_page.url} ##{article_page.name}") }
    end

    context 'when sitemap_page_state is show' do
      let(:item) { create :sitemap_page, cur_node: node, sitemap_page_state: 'show' }
      let(:article_node) { create :article_node_page }
      let!(:article_page) { create :article_page, cur_node: article_node }

      it { expect(item.load_sitemap_urls).to include(article_node.url) }
      it { expect(item.load_sitemap_urls).to include(article_page.url) }
      it { expect(item.load_sitemap_urls(name: true)).to include("#{article_node.url} ##{article_node.name}") }
      it { expect(item.load_sitemap_urls(name: true)).to include("#{article_page.url} ##{article_page.name}") }
    end
  end
end
