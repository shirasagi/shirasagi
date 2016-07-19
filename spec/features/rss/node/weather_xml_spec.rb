require 'spec_helper'

describe "Rss::Node::WeatherXml", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create(:rss_node_weather_xml, cur_site: site) }
  let(:index_path) { rss_weather_xmls_path site.id, node }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "basic crud" do
    let(:name0) { unique_id }
    let(:name1) { unique_id }
    let(:rss_link) { "http://example.jp/#{unique_id}.html" }
    let(:html) { "<p>#{unique_id}</p>" }
    let(:xml) { File.read(Rails.root.join(*%w(spec fixtures rss 9b43a982-fecf-3866-95e7-c375226a7c87.xml))) }

    before { login_cms_user }

    it do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path

      click_on '新規作成'
      fill_in 'item[name]', with: name0
      fill_in 'item[rss_link]', with: rss_link
      fill_in 'item[html]', with: html
      fill_in 'item[xml]', with: xml

      click_on '保存'
      expect(page).to have_css('#notice', text: '保存しました。')

      expect(Rss::WeatherXmlPage.count).to eq 1
      Rss::WeatherXmlPage.first.tap do |item|
        expect(item.name).to eq name0
        expect(item.rss_link).to eq rss_link
        expect(item.html).to eq html
        expect(item.xml).to eq xml.gsub("\n", "\r\n").strip
      end

      visit index_path
      click_on name0
      click_on '編集する'
      fill_in 'item[name]', with: name1

      click_on '保存'
      expect(page).to have_css('#notice', text: '保存しました。')

      Rss::WeatherXmlPage.first.tap do |item|
        expect(item.name).to eq name1
      end

      visit index_path
      click_on name1
      click_on '削除する'
      click_on '削除'
      expect(page).to have_css('#notice', text: '保存しました。')
    end
  end

  context "node conf" do
    let!(:region) { create :rss_weather_xml_region_126 }
    let!(:member_node_my_anpi_post) { create :member_node_my_anpi_post, cur_site: site }
    let!(:ezine_node_member_page) { create(:ezine_node_member_page, cur_site: site) }

    before do
      login_cms_user
    end

    it do
      visit index_path
      click_on 'フォルダー設定'

      click_on '編集する'
      fill_in 'item[hub_url]', with: "http://example.jp/#{unique_id}.html"
      fill_in 'item[topic_urls]', with: "http://example.jp/#{unique_id}.html"
      fill_in 'item[lease_seconds]', with: 300
      fill_in 'item[secret]', with: unique_id
      fill_in 'item[rss_max_docs]', with: 10
      select '非公開', from: 'item[page_state]'
      fill_in 'item[title_mail_text]', with: unique_id
      fill_in 'item[upper_mail_text]', with: unique_id
      fill_in 'item[loop_mail_text]', with: unique_id
      fill_in 'item[lower_mail_text]', with: unique_id
      select '6弱', from: 'item[earthquake_intensity]'
      click_on '地域を選択する'
      click_on region.name
      within '.mod-rss-anpi-mail-setting-my-anpi-post' do
        click_on 'フォルダーを選択する'
      end
      click_on member_node_my_anpi_post.name
      within '.mod-rss-anpi-mail-setting-anpi-mail' do
        click_on 'フォルダーを選択する'
      end
      click_on ezine_node_member_page.name

      click_on '保存'
      expect(page).to have_css('#notice', text: '保存しました。')
    end
  end
end
