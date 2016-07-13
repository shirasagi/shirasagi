require 'spec_helper'

describe 'cms_agents_nodes_archive', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:root_node) { create :article_node_page, cur_site: site }
  let!(:layout) { create_cms_layout }
  let!(:item) { create(:article_page, cur_site: site, cur_node: root_node, released: Time.zone.now) }

  context 'put archive node under article node' do
    let!(:archive_node) { create :cms_node_archive, cur_site: site, cur_node: root_node, layout_id: layout.id }
    let(:index_url) { "#{archive_node.full_url}#{Time.zone.now.year}#{format('%02d', Time.zone.now.month)}" }

    it do
      visit index_url
      expect(page).to have_css('body > div.cms-pages > article')
    end
  end

  context 'put archive node beside article node' do
    let!(:archive_node) { create :cms_node_archive, cur_site: site, layout_id: layout.id, conditions: root_node.filename }
    let(:index_url) { "#{archive_node.full_url}#{Time.zone.now.year}#{format('%02d', Time.zone.now.month)}" }

    it do
      visit index_url
      expect(page).to have_css('body > div.cms-pages > article')
    end
  end
end
