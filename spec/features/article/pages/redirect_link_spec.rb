require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create :article_node_page }
  let!(:item) { create :article_page, cur_node: node }
  let!(:redirect_link) { "http://#{unique_id}@example.jp" }

  let!(:new_path) { new_article_page_path site, node }
  let!(:show_path) { article_page_path site, node, item }
  let!(:edit_path) { edit_article_page_path site, node, item }

  before { login_cms_user }

  context "disable redirect_link (default case)" do
    it "#new" do
      visit new_path
      within "form#item-form" do
        expect(page).to have_no_css("#addon-cms-agents-addons-redirect_link")
        expect(page).to have_no_css('[name="item[redirect_link]"]')
      end
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        expect(page).to have_no_css("#addon-cms-agents-addons-redirect_link")
        expect(page).to have_no_css('[name="item[redirect_link]"]')
      end
    end

    it "#show" do
      visit show_path
      expect(page).to have_no_css("#addon-cms-agents-addons-redirect_link")
    end

    it "#show" do
      # 後から redirect_link を site 設定で非表示にした場合、登録されていることが分かるように、詳細画面に表示だけは残しておく。
      item.redirect_link = redirect_link
      item.update!

      visit show_path
      within "#addon-cms-agents-addons-redirect_link" do
        expect(page).to have_link redirect_link
      end
    end
  end

  context "enable redirect_link" do
    before do
      site.redirect_link_state = "enabled"
      site.update!
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        fill_in "item[redirect_link]", with: redirect_link
        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-cms-agents-addons-redirect_link" do
        expect(page).to have_link redirect_link
      end
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[redirect_link]", with: redirect_link
        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-cms-agents-addons-redirect_link" do
        expect(page).to have_link redirect_link
      end
    end

    it "#show" do
      item.redirect_link = redirect_link
      item.update!

      visit show_path
      within "#addon-cms-agents-addons-redirect_link" do
        expect(page).to have_link redirect_link
      end
    end
  end
end
