require 'spec_helper'

describe 'cms_agents_nodes_site_search', type: :feature, dbscope: :example, js: true, es: true do
  let(:site){ cms_site }
  let(:node) { create :article_node_page, cur_site: site }
  let(:part) do
    create :cms_part_free, cur_site: site, html:
      "<form action=\"#{site_search_node.url}\">
        <input type=\"text\" title=\"サイト内検索\" class=\"text\" id=\"search-box\" name=\"s[keyword]\">
        <input type=\"submit\" id=\"search-button\" value=\"検索\" name=\"sa\">
      </form>"
  end
  let(:layout) { create_cms_layout part }
  let!(:site_search_node) { create :cms_node_site_search, cur_site: site, cur_node: node }
  let(:name1) { unique_id.to_s }
  let(:name2) { unique_id.to_s }
  let(:requests) { [] }

  before do
    site_search_node.set(layout_id: layout.id)
    stub_request(:any, /#{::Regexp.escape(site.elasticsearch_hosts.first)}/).to_return do |request|
      if request.uri.path == "/"
        # always respond success for ping request
        {
          status: 200,
          headers: { 'Content-Type' => 'application/json; charset=UTF-8', 'X-elastic-product' => "Elasticsearch" },
          body: ::File.read("#{Rails.root}/spec/fixtures/gws/elasticsearch/ping.json")
        }
      else
        requests << request.as_json.dup
        {
          body: {
            took: 20,
            hits: {
              total: 2,
              hits: [
                {
                  _index: site.id.to_s,
                  _type: 'cms_pages',
                  _id: "post-1",
                  _source: {
                    name: name1,
                    url: "http://example.jp/#{name1}",
                    created: Time.zone.now,
                    updated: Time.zone.now,
                    released: Time.zone.now
                  }
                },
                {
                  _index: site.id.to_s,
                  _type: 'cms_pages',
                  _id: "post-2",
                  _source: {
                    name: name2,
                    url: "http://example.jp/#{name2}",
                    created: Time.zone.now,
                    updated: Time.zone.now,
                    released: Time.zone.now
                  }
                }
              ]
            }
          }.to_json,
          status: 200,
          headers: { 'Content-Type' => 'application/json; charset=UTF-8' }
        }
      end
    end
  end

  describe 'index' do
    it "#index" do
      visit site_search_node.url

      within '.search-form' do
        fill_in 's[keyword]', with: 'String'
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_css("form[action='#{site_search_node.url}']", count: 2)

      within '.search-result' do
        expect(page).to have_css('.search-stats')
        expect(page).to have_css('.pages .title', text: name1)
        expect(page).to have_css('.pages .title', text: name2)
      end
    end

    it "#index with kana", mecab: true do
      visit site_search_node.url.sub('/', SS.config.kana.location + '/')

      within '.search-form' do
        fill_in 's[keyword]', with: 'String'
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_css("form[action='#{site_search_node.url}']", count: 2)

      within '.search-result' do
        expect(page).to have_css('.search-stats')
        expect(page).to have_css('.pages .title', text: name1)
        expect(page).to have_css('.pages .title', text: name2)
      end
    end

    it "#index with mobile" do
      visit site_search_node.url.sub('/', site.mobile_location + '/')

      within '.search-form' do
        fill_in 's[keyword]', with: 'String'
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_css("form[action='#{site_search_node.url.sub('/', site.mobile_location + '/')}']", count: 2)

      within '.search-result' do
        expect(page).to have_css('.search-stats')
        expect(page).to have_css('.pages .title', text: name1)
        expect(page).to have_css('.pages .title', text: name2)
      end
    end
  end
end
