require 'spec_helper'

describe 'article_agents_pages_page', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node) { create(:article_node_page, cur_site: site, layout: layout) }
  let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout: layout) }

  before do
    FileUtils.rm_rf(node.path)
  end

  it do
    visit item.full_url
    expect(page).to have_css("[rel=\"canonical\"][href=\"#{item.full_url}\"]")
  end
end
