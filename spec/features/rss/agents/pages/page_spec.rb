require 'spec_helper'

describe "rss_agents_pages_page", dbscope: :example do
  let(:site) { cms_site }
  let(:article) { create :article_page }
  let(:node) { create :rss_node_page, site: site }
  let(:item) { create(:rss_page, site: site, node: node, rss_link: "http://#{site.domain}/#{article.filename}") }
  let(:index_url) { ::URI.parse "http://#{site.domain}/#{item.filename}"}

  it do
    visit index_url
    expect(status_code).to eq 200
    # it is expected that accessing index_url is redirected to article page
    expect(current_path).to eq "/#{article.filename}"
  end
end
