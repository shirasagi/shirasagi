require 'spec_helper'

describe "rss_agents_nodes_page", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :rss_node_page, site: site }
  let(:item) { create(:rss_page, site: site, node: node) }
  let(:index_url) { ::URI.parse "http://#{site.domain}/#{node.filename}/"}

  before { item }

  it do
    visit index_url
    expect(status_code).to eq 200
    within 'div.article-pages' do
      within "article.item-#{item.name}" do
        expect(page).to have_content(item.name)
      end
    end
  end
end
