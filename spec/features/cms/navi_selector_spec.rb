require 'spec_helper'

describe "move_cms_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }

  before { login_cms_user }

  context "without node" do
    it do
      visit cms_main_path(site: site)
      within first("#main .main-navi") do
        click_on I18n.t("cms.part")
      end
      within first("#main .main-navi") do
        expect(page).to have_css(".current[href='#{cms_parts_path(site: site)}']")
      end
      # フォルダーツリーの描画完了まで待機
      wait_for_turbo_frame "#cms-nodes-tree-frame"
    end
  end

  context "with node 'cms/page'" do
    let!(:node1) { create :cms_node_page, cur_site: site }

    it do
      # 標準機能/ページリスト
      visit node_pages_path(site: site, cid: node1)
      within first("#main .main-navi") do
        click_on I18n.t("cms.part")
      end
      within first("#main .main-navi") do
        expect(page).to have_css(".current[href='#{node_parts_path(site: site, cid: node1)}']")
      end
      # フォルダーツリーの描画完了まで待機
      wait_for_turbo_frame "#cms-nodes-tree-frame"
    end
  end

  context "with node 'article/page'" do
    let!(:node2) { create :article_node_page, cur_site: site }

    it do
      # 記事/記事リスト
      visit article_pages_path(site: site, cid: node2)
      within first("#main .main-navi") do
        click_on I18n.t("cms.part")
      end
      within first("#main .main-navi") do
        expect(page).to have_css(".current[href='#{node_parts_path(site: site, cid: node2)}']")
      end
      # フォルダーツリーの描画完了まで待機
      wait_for_turbo_frame "#cms-nodes-tree-frame"
    end
  end

  context "with node 'event/page'" do
    let!(:node3) { create :event_node_page, cur_site: site }

    it do
      # イベント/イベントリスト
      visit event_pages_path(site: site, cid: node3)
      within first("#main .main-navi") do
        click_on I18n.t("cms.part")
      end
      within first("#main .main-navi") do
        expect(page).to have_css(".current[href='#{node_parts_path(site: site, cid: node3)}']")
      end
      # フォルダーツリーの描画完了まで待機
      wait_for_turbo_frame "#cms-nodes-tree-frame"
    end
  end

  context "with node 'faq/page'" do
    let!(:node4) { create :faq_node_page, cur_site: site }

    it do
      # FAQ/FAQ記事リスト
      visit faq_pages_path(site: site, cid: node4)
      within first("#main .main-navi") do
        click_on I18n.t("cms.part")
      end
      within first("#main .main-navi") do
        expect(page).to have_css(".current[href='#{node_parts_path(site: site, cid: node4)}']")
      end
      # フォルダーツリーの描画完了まで待機
      wait_for_turbo_frame "#cms-nodes-tree-frame"
    end
  end

  context "with node 'category/page'" do
    let!(:node5) { create :category_node_page, cur_site: site }

    it do
      # カテゴリー/ページリスト
      visit category_pages_path(site: site, cid: node5)
      within first("#main .main-navi") do
        click_on I18n.t("cms.part")
      end
      within first("#main .main-navi") do
        expect(page).to have_css(".current[href='#{node_parts_path(site: site, cid: node5)}']")
      end
      # フォルダーツリーの描画完了まで待機
      wait_for_turbo_frame "#cms-nodes-tree-frame"
    end
  end

  context "with node 'inquiry/form'" do
    let!(:node6) { create :inquiry_node_form, cur_site: site }

    it do
      # メールフォーム/フォーム
      visit inquiry_forms_path(site: site, cid: node6)
      within first("#main .main-navi") do
        click_on I18n.t("cms.part")
      end
      within first("#main .main-navi") do
        expect(page).to have_css(".current[href='#{node_parts_path(site: site, cid: node6)}']")
      end
      # フォルダーツリーの描画完了まで待機
      wait_for_turbo_frame "#cms-nodes-tree-frame"
    end
  end
end
