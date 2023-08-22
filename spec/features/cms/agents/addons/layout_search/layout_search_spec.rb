require 'spec_helper'

describe 'レイアウト検索', type: :feature, dbscope: :example, js: true do
	
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:user) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }
  let(:item) { create :cms_layout, filename: "#{node.filename}/name" }
  let(:layout_name) { unique_id }
  subject(:search_index_path)  { cms_search_contents_pages_path node }
  
  before do
    dummy_item = create(:cms_layout, filename: "#{node.filename}/dummy_name")
    html1 = "<div>html1</div>"
    html2 = "<div>html2</div>"

    create(
      :cms_page, cur_site: site, user: user, name: "[TEST]A", filename: "A.html", state: "public",
      layout_id: item.id, html: html1)
    create(
      :cms_page, cur_site: site, user: user, name: "[TEST]B", filename: "B.html", state: "public",
      layout_id: dummy_item.id,  html: html1)

    login_cms_user
  end

  context "レイアウト詳細からサイト内検索へ" do

    subject(:layout_index_path)  { cms_layouts_path node }
    subject(:layout_show_path) { "#{layout_index_path}/#{item.id}" }
		 
    it do
      visit layout_show_path
      expect(current_path).to eq layout_show_path
      expect(page).to have_content ("レイアウト使用ページを検索する")

      click_on I18n.t("modules.addons.cms/layout_search/btn")
      expect(current_path).to eq search_index_path

      click_button I18n.t('ss.buttons.search')
      expect(page).to have_css(".search-count", text: "1 件の検索結果")
      expect(page).to have_css("div.info a.title", text: "[TEST]A")
    end
  end

  context "サイト内検索でレイアウト使用ページを検索" do
    it "search with layout" do
      visit search_index_path
      wait_cbox_open { click_on I18n.t("cms.apis.layouts.index") }
      wait_for_cbox do
        click_on item.name
      end
      click_button I18n.t('ss.buttons.search')

      expect(page).to have_css(".search-count", text: "1 件の検索結果")
      expect(page).to have_css("div.info a.title", text: "[TEST]A")
    end
  end
end
