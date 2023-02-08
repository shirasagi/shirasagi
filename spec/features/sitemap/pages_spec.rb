require 'spec_helper'

describe "sitemap_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :sitemap_node_page, filename: "docs", name: "sitemap" }
  let(:item) { create :sitemap_page, cur_site: site, cur_node: node }
  let(:index_path) { sitemap_pages_path site.id, node }
  let(:new_path) { new_sitemap_page_path site.id, node }
  let(:show_path) { sitemap_page_path site.id, node, item }
  let(:edit_path) { edit_sitemap_page_path site.id, node, item }
  let(:delete_path) { delete_sitemap_page_path site.id, node, item }
  let(:move_path) { move_sitemap_page_path site.id, node, item }
  let(:copy_path) { copy_sitemap_page_path site.id, node, item }
  let!(:article_node) { create_once :article_node_page }
  let!(:article_page) { create :article_page, cur_site: site, cur_node: article_node }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        select I18n.t('ss.options.state.show'), from: 'item[sitemap_page_state]'
        click_button I18n.t('sitemap.buttons.export_urls')
        expect(page).to have_css(".CodeMirror", text: article_page.url)
        click_button I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")

      item = Sitemap::Page.all.first
      expect(item.sitemap_urls).to include(node.url)
      expect(item.sitemap_urls).not_to include(item.url)
      expect(item.sitemap_urls).to include(article_node.url)
      expect(item.sitemap_urls).to include(article_page.url)
    end

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        select I18n.t('ss.options.state.show'), from: 'item[sitemap_page_state]'
        click_button I18n.t('sitemap.buttons.export_urls')
        expect(page).to have_css(".CodeMirror", text: article_page.url)
        click_button I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")

      item.reload
      expect(item.sitemap_urls).to include(node.url)
      expect(item.sitemap_urls).to include(item.url)
      expect(item.sitemap_urls).to include(article_node.url)
      expect(item.sitemap_urls).to include(article_page.url)
    end

    it "#move" do
      visit move_path
      within "form" do
        fill_in "destination", with: "docs/destination"
        click_button I18n.t('ss.buttons.move')
      end
      wait_for_notice I18n.t('ss.notice.moved')
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "docs/destination.html")

      within "form" do
        fill_in "destination", with: "docs/sample"
        click_button I18n.t('ss.buttons.move')
      end
      wait_for_notice I18n.t('ss.notice.moved')
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "docs/sample.html")
    end

    it "#copy" do
      visit copy_path
      within "form" do
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(current_path).to eq index_path
      expect(page).to have_css("a", text: "[複製] #{item.name}")
      expect(page).to have_css(".state", text: "非公開")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(current_path).to eq index_path
    end

    it "workflow" do
      visit edit_path
      expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
      expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
      expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")

      item.update state: 'close'
      visit edit_path
      expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
      expect(page).to have_no_css(".branch_save")
      expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")

      # not permitted
      role = cms_user.cms_roles[0]
      role.update permissions: role.permissions.reject { |k, v| k =~ /^(release_|close_)/ }

      visit edit_path
      expect(page).to have_no_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
      expect(page).to have_no_css(".branch_save")
      expect(page).to have_no_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")

      item.update state: 'public'
      visit edit_path
      expect(page).to have_no_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
      expect(page).to have_css(".branch_save")
      expect(page).to have_no_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
    end
  end
end
