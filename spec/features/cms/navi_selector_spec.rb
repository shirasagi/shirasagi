require 'spec_helper'

describe "move_cms_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node1) { create :cms_node_page, cur_site: site }
  let!(:node2) { create :article_node_page, cur_site: site }
  let!(:node3) { create :event_node_page, cur_site: site }
  let!(:node4) { create :faq_node_page, cur_site: site }
  let!(:node5) { create :category_node_page, cur_site: site }
  let!(:node6) { create :inquiry_node_form, cur_site: site }

  before { login_cms_user }

  it do
    visit cms_main_path(site: site)
    within first(".main-navi") do
      click_on I18n.t("cms.part")
    end
    within first(".main-navi") do
      expect(page).to have_css(".current[href='#{cms_parts_path(site: site)}']")
    end
    # フォルダーツリーの描画完了まで待機
    within ".tree-navi" do
      expect(page).to have_css(".content-navi-refresh", text: "refresh")
    end

    # 標準機能/ページリスト
    visit node_pages_path(site: site, cid: node1)
    within first(".main-navi") do
      click_on I18n.t("cms.part")
    end
    within first(".main-navi") do
      expect(page).to have_css(".current[href='#{node_parts_path(site: site)}']")
    end
    # フォルダーツリーの描画完了まで待機
    within ".tree-navi" do
      expect(page).to have_css(".content-navi-refresh", text: "refresh")
    end

    # 記事/記事リスト
    visit article_pages_path(site: site, cid: node2)
    within first(".main-navi") do
      click_on I18n.t("cms.part")
    end
    within first(".main-navi") do
      expect(page).to have_css(".current[href='#{node_parts_path(site: site, cid: node2)}']")
    end
    # フォルダーツリーの描画完了まで待機
    within ".tree-navi" do
      expect(page).to have_css(".content-navi-refresh", text: "refresh")
    end

    # イベント/イベントリスト
    visit event_pages_path(site: site, cid: node3)
    within first(".main-navi") do
      click_on I18n.t("cms.part")
    end
    within first(".main-navi") do
      expect(page).to have_css(".current[href='#{node_parts_path(site: site, cid: node3)}']")
    end
    # フォルダーツリーの描画完了まで待機
    within ".tree-navi" do
      expect(page).to have_css(".content-navi-refresh", text: "refresh")
    end

    # FAQ/FAQ記事リスト
    visit faq_pages_path(site: site, cid: node4)
    within first(".main-navi") do
      click_on I18n.t("cms.part")
    end
    within first(".main-navi") do
      expect(page).to have_css(".current[href='#{node_parts_path(site: site, cid: node4)}']")
    end
    # フォルダーツリーの描画完了まで待機
    within ".tree-navi" do
      expect(page).to have_css(".content-navi-refresh", text: "refresh")
    end

    # カテゴリー/ページリスト
    visit category_pages_path(site: site, cid: node5)
    within first(".main-navi") do
      click_on I18n.t("cms.part")
    end
    within first(".main-navi") do
      expect(page).to have_css(".current[href='#{node_parts_path(site: site, cid: node5)}']")
    end
    # フォルダーツリーの描画完了まで待機
    within ".tree-navi" do
      expect(page).to have_css(".content-navi-refresh", text: "refresh")
    end

    # メールフォーム/フォーム
    visit inquiry_forms_path(site: site, cid: node6)
    within first(".main-navi") do
      click_on I18n.t("cms.part")
    end
    within first(".main-navi") do
      expect(page).to have_css(".current[href='#{node_parts_path(site: site, cid: node6)}']")
    end
    # フォルダーツリーの描画完了まで待機
    within ".tree-navi" do
      expect(page).to have_css(".content-navi-refresh", text: "refresh")
    end
  end
end
