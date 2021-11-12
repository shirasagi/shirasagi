require 'spec_helper'

describe "jmaxml/quake_regions", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :rss_node_weather_xml, cur_site: site }
  let(:index_path) { jmaxml_quake_regions_path(site, node) }

  context "basic crud" do
    let(:code) { unique_id }
    let(:name) { unique_id }
    let(:yomi1) { unique_id }
    let(:yomi2) { unique_id }
    before { login_cms_user }

    it do
      #
      # create
      #
      visit index_path
      click_on I18n.t('ss.links.new')

      within 'form' do
        fill_in 'item[code]', with: code
        fill_in 'item[name]', with: name
        fill_in 'item[yomi]', with: yomi1
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'), wait: 60)

      expect(Jmaxml::QuakeRegion.count).to eq 1
      Jmaxml::QuakeRegion.first.tap do |region|
        expect(region.code).to eq code
        expect(region.name).to eq name
        expect(region.yomi).to eq yomi1
      end

      #
      # update
      #
      visit index_path
      click_on name
      click_on I18n.t('ss.links.edit')

      within 'form' do
        fill_in 'item[yomi]', with: yomi2
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'), wait: 60)

      expect(Jmaxml::QuakeRegion.count).to eq 1
      Jmaxml::QuakeRegion.first.tap do |region|
        expect(region.code).to eq code
        expect(region.name).to eq name
        expect(region.yomi).to eq yomi2
      end

      #
      # delete
      #
      visit index_path
      click_on name
      click_on I18n.t('ss.links.delete')

      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'), wait: 60)

      expect(Jmaxml::QuakeRegion.count).to eq 0
    end
  end

  context 'search' do
    let!(:region) { create :jmaxml_region_c126 }

    before { login_cms_user }

    it do
      visit index_path
      expect(page).to have_css('.list-item .title', text: region.name)

      fill_in 's[keyword]', with: region.name
      click_on I18n.t('ss.buttons.search')
      expect(page).to have_css('.list-item .title', text: region.name)

      visit index_path
      fill_in 's[keyword]', with: unique_id
      click_on I18n.t('ss.buttons.search')

      expect(page).to have_no_css('.list-item .title', text: region.name)
    end
  end
end
