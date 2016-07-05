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
<<<<<<< HEAD:spec/features/article/pages/basic_crud_spec.rb
=======
  let(:lock_path) { lock_article_page_path site.id, node, item }
  let(:import_path) { import_article_pages_path site.id, node }
>>>>>>> RSpec code created AND some bug fix:spec/features/article/pages_spec.rb

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
<<<<<<< HEAD:spec/features/article/pages/basic_crud_spec.rb
=======

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
      end

      scenario "button click" do
        visit index_path
        expect(status_code).to eq 200

        click_button I18n.t("views.links.download")
        expect(status_code).to eq 200
        expect(current_path).to eq index_path

        csv_lines = CSV.parse(page.html.encode("UTF-8"))
        expect(csv_lines.length).to eq 1
        expect(csv_lines[0]).to eq %w(id name file_name layout order keywords description summary_html html categories parent_crumb_urls event_name event_dates contact_state contact_group contact_charge contact_tel contact_fax contact_email released release_date close_date groups permission_level).map { |k| Article::Page.t k.to_sym }
#        expect(csv_lines[1]).to include(logs[0].class_name)
#        expect(csv_lines[1]).to include(logs[0].start_label)
#        expect(csv_lines[1]).to include(I18n.t(logs[0].state, scope: "job.state"))


      end
    end

    feature "#import", js: true do
      scenario "button click" do
        visit index_path
        expect(status_code).to eq(200).or eq(304)

        click_button I18n.t("views.links.import")
        expect(status_code).to eq(200)
        expect(current_path).to eq import_path
      end
    end
>>>>>>> RSpec code created AND some bug fix:spec/features/article/pages_spec.rb
  end
end
