require 'spec_helper'

describe 'cms_agents_nodes_site_search', type: :feature, dbscope: :example, js: true, es: true do
  let(:site){ cms_site }
  let(:node) { create :article_node_page, cur_site: site }
  let(:layout) { create_cms_layout }
  let!(:site_search_node) { create :cms_node_site_search, cur_site: site, cur_node: node, layout_id: layout.id }
  let(:name) { unique_id.to_s }
  let(:requests) { [] }

  before do
    stub_request(:any, /#{::Regexp.escape(site.elasticsearch_hosts.first)}/).to_return do |request|
      requests << request.as_json.dup
      {
        body: {
          took: 20,
          hits: {
            total: 1,
            hits: [{
              _index: "#{site.id}",
              _type: 'cms_pages',
              _id: "post-1",
              _source: {
                name: name,
                url: "http://example.jp/#{name}",
                updated: Time.zone.now,
                released: Time.zone.now
              }
            }]
          }
        }.to_json,
        status: 200,
        headers: { 'Content-Type' => 'application/json; charset=UTF-8' }
      }
    end
  end

  describe 'index' do
    it do
      visit site_search_node.url

      within '.search-form' do
        fill_in 's[keyword]', with: 'String'
        click_button I18n.t('ss.buttons.search')
      end

      within '.search-result' do
        expect(page).to have_css('.search-stats')
        expect(page).to have_css('.pages .title', text: name)
      end
    end
  end
end
