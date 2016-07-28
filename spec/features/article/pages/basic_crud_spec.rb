require 'spec_helper'
require "csv"

describe "article_pages", dbscope: :example do
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
  let(:lock_path) { lock_article_page_path site.id, node, item }
  let(:import_path) { import_article_pages_path site.id, node }

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
        fill_in "item[basename]", with: "sample"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#move" do
      visit move_path
      within "form" do
        fill_in "destination", with: "docs/destination"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "docs/destination.html")

      within "form" do
        fill_in "destination", with: "docs/sample"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "docs/sample.html")
    end

    it "#copy" do
      visit copy_path
      within "form" do
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
      expect(page).to have_css("a", text: "[複製] #{item.name}")
      expect(page).to have_css(".state", text: "非公開")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end

    feature "lock and unlock" do
      given(:group) { cms_group }
      given(:user1) { create(:cms_test_user, group: group) }

      background do
        item.acquire_lock(user: user1)
      end

      scenario "locked by other then unlock and edit forcibly" do
        expect(item.lock_owner_id).not_to eq cms_user.id

        visit show_path
        expect(status_code).to eq 200

        within "div#addon-cms-agents-addons-edit_lock" do
          expect(page).to have_content(I18n.t("errors.messages.locked", user: item.lock_owner.long_name))
        end

        click_link "編集する"
        expect(status_code).to eq 200
        expect(current_path).to eq lock_path

        click_button I18n.t("views.button.unlock_and_edit_forcibly")
        expect(status_code).to eq 200
        expect(current_path).to eq edit_path

        item.reload
        expect(item.lock_owner_id).to eq cms_user.id
      end
    end

    feature "#download", js: true do
      background do
        create :article_page, cur_site: site, cur_node: node
        create :article_page, cur_site: site, cur_node: node
      end

      scenario "click on download button without check in checkbox" do
        visit index_path
        expect(status_code).to eq 200

        click_button I18n.t("views.links.download")
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page.response_headers['Content-Disposition']).to match(/filename="article_pages_[\d]+\.csv"$/)
      end

      scenario "click on download button to check in checkbox" do
        visit index_path
        expect(status_code).to eq 200

        all(".check")[1].click
        expect(page).to have_checked_field 'ids[]'

        click_button I18n.t("views.links.download")
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page.response_headers['Content-Disposition']).to match(/filename="article_pages_[\d]+\.csv"$/)
      end
    end

    feature "#import", js: true do

      feature "import success" do
        background do
          create :cms_node, cur_site: site, name: "くらしのガイド"
          create :cms_layout, cur_site: site, name: "記事レイアウト"
          create :ss_group, name: "シラサギ市/企画政策部/政策課"
          create :article_page, cur_site: site, cur_node: node
          create :article_page, cur_site: site, cur_node: node
        end

        scenario "exec import process" do
          visit index_path
          expect(status_code).to eq(200).or eq(304)

          click_button I18n.t("views.links.import")
          expect(status_code).to eq(200)
          expect(current_path).to eq import_path

          attach_file "item_in_file", "spec/fixtures/article/article_import_test_1.csv"
          click_button I18n.t("views.links.import")
          expect(status_code).to eq(200)
          expect(page).to have_content I18n.t("views.notice.saved") 
        end

        scenario "check import data" do
          visit index_path
          click_button I18n.t("views.links.import")
          expect(current_path).to eq import_path

          attach_file "item_in_file", "spec/fixtures/article/article_import_test_1.csv"
          click_button I18n.t("views.links.import")
          expect(status_code).to eq(200)

          click_link 'test_1_title' 
          expect(status_code).to eq(200)

          expect(page).to have_content 'test_1_title'
          expect(page).to have_content 'docs/test_1.html'
          expect(page).to have_content '記事レイアウト'
          expect(page).to have_content 'test_1_keyword'
          expect(page).to have_content 'test_1_overview'
          expect(page).to have_content 'test_1_summary'
          expect(page).to have_content 'test_1_parent_crumb_urls'
          expect(page).to have_content 'test_1_event_title'
          expect(page).to have_content 'シラサギ市/企画政策部/政策課'
          expect(page).to have_content 'test_1_contact_charge'
          expect(page).to have_content 'test_1_contact_tel'
          expect(page).to have_content 'test_1_contact_fax'
          expect(page).to have_content 'test_1_contact_mail'
        end

        scenario "fail import process" do
          visit index_path
          expect(status_code).to eq(200).or eq(304)

          click_button I18n.t("views.links.import")
          expect(status_code).to eq(200)
          expect(current_path).to eq import_path

          attach_file "item_in_file", "spec/fixtures/article/article_import_test_2.csv"
          click_button I18n.t("views.links.import")
          expect(status_code).to eq(200)
          expect(current_path).to eq import_path
          expect(page).to have_content I18n.t("views.notice.saved") 
          expect(page).to have_content I18n.t('errors.messages.invalid')

          visit index_path
          expect(page).to have_content 'test_1_title'
          expect(page).to have_content 'test_2_title'
          expect(page).to_not have_content 'test_3_title'
        end


      end
    end
>>>>>>> RSpec code created AND some bug fix:spec/features/article/pages_spec.rb
  end
end
