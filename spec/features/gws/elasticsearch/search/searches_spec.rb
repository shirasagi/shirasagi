require 'spec_helper'

describe "gws_elasticsearch_search", type: :feature, dbscope: :example, js: true, es: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:path) { gws_elasticsearch_search_search_path(site: site.id, type: 'all') }
  let(:name) { unique_id.to_s }
  let(:requests) { [] }

  before do
    login_gws_user

    create(:gws_board_category, name: 'Category')
    create(:gws_faq_category, name: 'Category')
    create(:gws_qna_category, name: 'Category')
    create(:gws_monitor_category, name: 'Category')
    create(:gws_share_category, name: 'Category')

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
              total: 1,
              hits: [{
                _index: site.id.to_s,
                _type: '_doc',
                _id: "gws_board_posts-post-1",
                _source: {
                  collection_name: 'gws_board_posts',
                  name: name,
                  url: "http://example.jp/#{name}",
                  updated: Time.zone.now,
                  categories: %w(Category)
                }
              }]
            }
          }.to_json,
          status: 200,
          headers: { 'Content-Type' => 'application/json; charset=UTF-8' }
        }
      end
    end
  end

  describe '#index' do
    it do
      visit gws_elasticsearch_search_search_path(site: site.id, type: 'unknown')
      # expect 404

      visit gws_elasticsearch_search_search_path(site: site.id, type: 'all')
      within '.index form' do
        fill_in 's[keyword]', with: 'String'
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item .title', text: name)

      visit gws_elasticsearch_search_search_path(site: site.id, type: 'board', s: { keyword: 'String' })
      expect(page).to have_css('.list-item .title', text: name)

      visit gws_elasticsearch_search_search_path(site: site.id, type: 'faq', s: { keyword: 'String' })
      expect(page).to have_css('.list-item .title', text: name)

      visit gws_elasticsearch_search_search_path(site: site.id, type: 'qna', s: { keyword: 'String' })
      expect(page).to have_css('.list-item .title', text: name)

      visit gws_elasticsearch_search_search_path(site: site.id, type: 'report', s: { keyword: 'String' })
      expect(page).to have_css('.list-item .title', text: name)

      visit gws_elasticsearch_search_search_path(site: site.id, type: 'workflow', s: { keyword: 'String' })
      expect(page).to have_css('.list-item .title', text: name)

      visit gws_elasticsearch_search_search_path(site: site.id, type: 'workflow_form', s: { keyword: 'String' })
      expect(page).to have_css('.list-item .title', text: name)

      visit gws_elasticsearch_search_search_path(site: site.id, type: 'circular', s: { keyword: 'String' })
      expect(page).to have_css('.list-item .title', text: name)

      visit gws_elasticsearch_search_search_path(site: site.id, type: 'monitor', s: { keyword: 'String' })
      expect(page).to have_css('.list-item .title', text: name)

      visit gws_elasticsearch_search_search_path(site: site.id, type: 'survey', s: { keyword: 'String' })
      expect(page).to have_css('.list-item .title', text: name)

      visit gws_elasticsearch_search_search_path(site: site.id, type: 'share', s: { keyword: 'String' })
      expect(page).to have_css('.list-item .title', text: name)

      visit gws_elasticsearch_search_search_path(site: site.id, type: 'memo', s: { keyword: 'String' })
      expect(page).to have_css('.list-item .title', text: name)
    end
  end
end
