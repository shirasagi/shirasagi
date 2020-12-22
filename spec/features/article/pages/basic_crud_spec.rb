require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:item) { create(:article_page, cur_node: node) }
  let(:index_path) { article_pages_path site.id, node }
  let(:new_path) { new_article_page_path site.id, node }
  let(:show_path) { article_page_path site.id, node, item }
  let(:edit_path) { edit_article_page_path site.id, node, item }
  let(:delete_path) { delete_article_page_path site.id, node, item }
  let(:move_path) { move_article_page_path site.id, node, item }
  let(:copy_path) { copy_article_page_path site.id, node, item }
  let(:contains_urls_path) { contains_urls_article_page_path site.id, node, item }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_on I18n.t("ss.links.input")
        fill_in "item[basename]", with: "sample"
        click_on I18n.t("ss.buttons.draft_save")
      end
      click_on I18n.t("ss.buttons.ignore_alert")
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#move" do
      visit move_path
      within "form" do
        fill_in "destination", with: "docs/destination"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css("form#item-form h2", text: "docs/destination.html")

      within "form" do
        fill_in "destination", with: "docs/sample"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css("form#item-form h2", text: "docs/sample.html")
    end

    it "#copy" do
      visit copy_path
      within "form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css("a", text: "[複製] #{item.name}")
      expect(page).to have_css(".state", text: "非公開")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end

    it "#contains_urls" do
      visit contains_urls_path
      expect(page).to have_css("#addon-basic", text: item.name)
      expect(page).to have_css(".list-head", text: I18n.t("cms.confirm.contains_urls_not_found"))
    end
  end

  context "update page without required params" do
    before { login_cms_user }

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        # set to blank
        fill_in "item[name]", with: ""
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#errorExplanation', text: I18n.t('errors.messages.blank'))
    end
  end
end
