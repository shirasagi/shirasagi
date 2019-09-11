require 'spec_helper'

describe "event_pages", type: :feature, js: true do
  subject(:site) { cms_site }
  subject(:node) { create_once :event_node_page, filename: "docs", name: "event" }
  subject(:item) { Event::Page.last }
  subject(:index_path) { event_pages_path site.id, node }
  subject(:new_path) { new_event_page_path site.id, node }
  subject(:show_path) { event_page_path site.id, node, item }
  subject(:edit_path) { edit_event_page_path site.id, node, item }
  subject(:delete_path) { delete_event_page_path site.id, node, item }
  subject(:move_path) { move_event_page_path site.id, node, item }
  subject(:copy_path) { copy_event_page_path site.id, node, item }
  subject(:import_path) { import_event_pages_path site.id, node }
  subject(:contains_urls_path) { contains_urls_event_page_path site.id, node, item }

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
        click_on I18n.t("ss.links.input")
        fill_in "item[basename]", with: "sample"
        click_on I18n.t("ss.buttons.draft_save")
      end
      click_on I18n.t("ss.buttons.ignore_alert")
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
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
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "docs/destination.html")

      within "form" do
        fill_in "destination", with: "docs/sample"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "docs/sample.html")
    end

    it "#copy" do
      visit copy_path
      within "form" do
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).to eq index_path
      expect(page).to have_css("a", text: "[複製] modify")
      expect(page).to have_css(".state", text: "非公開")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end

    it "#contains_urls" do
      visit contains_urls_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#import" do
      visit import_path

      within "form#task-form" do
        attach_file "item[file]", "#{Rails.root}/spec/fixtures/event/import_job/event_pages.csv"
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end
      expect(page).to have_content I18n.t("ss.notice.started_import")
    end
  end
end
