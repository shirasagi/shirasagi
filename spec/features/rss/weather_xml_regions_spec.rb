require 'spec_helper'

describe 'rss_weather_xml_regions', dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create(:rss_node_weather_xml, cur_site: site) }
  let(:index_path) { rss_weather_xml_regions_path site.id, node }

  context 'without login' do
    it do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq sns_login_path
    end
  end

  context 'without auth' do
    it do
      login_ss_user
      visit index_path
      expect(status_code).to eq 403
    end
  end

  context 'basic crud' do
    let(:name0) { unique_id }
    let(:name1) { unique_id }
    let(:code) { unique_id }

    before { login_cms_user }

    it do
      visit index_path
      click_on '新規作成'
      fill_in 'item[name]', with: name0
      fill_in 'item[code]', with: code

      click_on '保存'
      expect(page).to have_css('#notice', text: '保存しました。')

      expect(Rss::WeatherXmlRegion.count).to eq 1
      Rss::WeatherXmlRegion.first.tap do |region|
        expect(region.name).to eq name0
        expect(region.code).to eq code
      end

      visit index_path
      expect(page).to have_css('.list-item .title', text: name0)
      click_on name0
      click_on '編集する'
      fill_in 'item[name]', with: name1

      click_on '保存'
      expect(page).to have_css('#notice', text: '保存しました。')

      Rss::WeatherXmlRegion.first.tap do |region|
        expect(region.name).to eq name1
      end

      visit index_path
      click_on name1
      click_on '削除する'
      click_on '削除'
      expect(page).to have_css('#notice', text: '保存しました。')
    end
  end

  context 'search' do
    let!(:region) { create :rss_weather_xml_region_126 }

    before { login_cms_user }

    it do
      visit index_path
      expect(page).to have_css('.list-item .title', text: region.name)

      fill_in 's[keyword]', with: region.name
      click_on '検索'
      expect(page).to have_css('.list-item .title', text: region.name)

      visit index_path
      fill_in 's[keyword]', with: unique_id
      click_on '検索'

      expect(page).not_to have_css('.list-item .title', text: region.name)
    end
  end
end
