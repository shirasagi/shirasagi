require 'spec_helper'

describe "Rss::Node::WeatherXml", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create(:rss_node_weather_xml, cur_site: site) }
  let(:index_path) { rss_weather_xmls_path site.id, node }

  context "basic crud" do
    let(:name0) { unique_id }
    let(:name1) { unique_id }
    let(:rss_link) { "http://example.jp/#{unique_id}.html" }
    let(:html) { "<p>#{unique_id}</p>" }
    let(:xml) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 9b43a982-fecf-3866-95e7-c375226a7c87.xml))) }

    before { login_cms_user }

    it do
      visit index_path
      expect(current_path).to eq index_path

      click_on I18n.t('ss.links.new')
      fill_in 'item[name]', with: name0
      fill_in 'item[rss_link]', with: rss_link
      fill_in 'item[html]', with: html

      click_on I18n.t('ss.buttons.save')
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'), wait: 60)

      expect(Rss::WeatherXmlPage.count).to eq 1
      Rss::WeatherXmlPage.first.tap do |item|
        expect(item.name).to eq name0
        expect(item.rss_link).to eq rss_link
        expect(item.html).to eq html
      end

      visit index_path
      click_on name0
      click_on I18n.t('ss.links.edit')
      fill_in 'item[name]', with: name1

      click_on I18n.t('ss.buttons.save')
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'), wait: 60)

      Rss::WeatherXmlPage.first.tap do |item|
        expect(item.name).to eq name1
      end

      visit index_path
      click_on name1
      click_on I18n.t('ss.links.delete')
      click_on I18n.t('ss.buttons.delete')
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'), wait: 60)
    end
  end

  context "node conf" do
    let!(:region) { create :jmaxml_region_c126 }
    let!(:member_node_my_anpi_post) { create :member_node_my_anpi_post, cur_site: site }
    let!(:ezine_node_member_page) { create(:ezine_node_member_page, cur_site: site) }

    before do
      login_cms_user
    end

    it do
      visit index_path
      click_on I18n.t("cms.node_config")

      click_on I18n.t('ss.links.edit')
      fill_in 'item[rss_max_docs]', with: 10
      select I18n.t("ss.options.state.closed"), from: 'item[page_state]'
      fill_in 'item[title_mail_text]', with: unique_id
      fill_in 'item[upper_mail_text]', with: unique_id
      fill_in 'item[loop_mail_text]', with: unique_id
      fill_in 'item[lower_mail_text]', with: unique_id
      select I18n.t("rss.options.earthquake_intensity.6-"), from: 'item[earthquake_intensity]'

      click_on I18n.t("jmaxml.apis.quake_regions.index")
      wait_for_cbox do
        click_on region.name
      end
      within ".mod-rss-anpi-mail-setting-regions" do
        expect(page).to have_css(".index", text: region.name)
      end

      within '.mod-rss-anpi-mail-setting-my-anpi-post' do
        wait_cbox_open do
          click_on I18n.t("cms.apis.nodes.index")
        end
      end
      wait_for_cbox do
        expect(page).to have_css("span.select-item", text: member_node_my_anpi_post.name)
        wait_cbox_close do
          find("#cboxClose").click
        end
      end
      within '.mod-rss-anpi-mail-setting-my-anpi-post' do
        expect(page).to have_css(".index", text: member_node_my_anpi_post.name)
      end

      within '.mod-rss-anpi-mail-setting-anpi-mail' do
        wait_cbox_open do
          click_on I18n.t("cms.apis.nodes.index")
        end
      end
      wait_for_cbox do
        expect(page).to have_css("span.select-item", text: ezine_node_member_page.name)
        wait_cbox_close do
          find("#cboxClose").click
        end
      end
      within '.mod-rss-anpi-mail-setting-anpi-mail' do
        expect(page).to have_css(".index", text: ezine_node_member_page.name)
      end

      click_on I18n.t('ss.buttons.save')
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end
  end
end
