require 'spec_helper'

describe "rss_agents_pages_page", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:article) { create :article_page, cur_site: site }
  let!(:node) { create :rss_node_page, cur_site: site }
  let!(:item) { create(:rss_page, cur_site: site, cur_node: node, rss_link: article.full_url) }

  before do
    FileUtils.rm_f(article.path)
    FileUtils.rm_f(item.path)
    FileUtils.rm_rf(node.path)
  end

  it do
    # item.full_url にアクセスすると rss_link にアクセスしたのと同じになるので、
    # full_url を自分で組み立ててアクセスしてみる。
    visit Addressable::URI.join(site.full_root_url, "#{item.filename}/").to_s
    expect(status_code).to eq 200
    # it is expected that accessing index_url is redirected to article page
    expect(current_path).to eq article.url
  end
end
