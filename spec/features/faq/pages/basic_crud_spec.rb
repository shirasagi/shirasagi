require 'spec_helper'

describe "faq_pages", type: :feature, js: true do
  subject(:site) { cms_site }
  subject(:node) { create_once :faq_node_page, filename: "docs", name: "faq" }
  subject(:item) { Faq::Page.last }
  subject(:index_path) { faq_pages_path site.id, node }
  subject(:new_path) { new_faq_page_path site.id, node }
  subject(:show_path) { faq_page_path site.id, node, item }
  subject(:edit_path) { edit_faq_page_path site.id, node, item }
  subject(:delete_path) { delete_faq_page_path site.id, node, item }
  subject(:delete_path2) { delete_faq_page_path site.id, node, item2 }
  subject(:move_path) { move_faq_page_path site.id, node, item }
  subject(:copy_path) { copy_faq_page_path site.id, node, item }
  subject(:import_path) { import_faq_pages_path site.id, node }
  subject(:contains_urls_path) { contains_urls_faq_page_path site.id, node, item }

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
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
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
        click_button I18n.t('ss.buttons.move')
      end
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "docs/destination.html")

      within "form" do
        fill_in "destination", with: "docs/sample"
        click_button I18n.t('ss.buttons.move')
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
      expect(page).to have_css(".delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(current_path).to eq index_path
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end

    it "#contains_urls" do
      visit contains_urls_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#import" do
      visit import_path

      within "form#task-form" do
        attach_file "item[file]", "#{Rails.root}/spec/fixtures/faq/import_job/faq_pages.csv"
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end
      expect(page).to have_content I18n.t("ss.notice.started_import")
    end
  end
end

describe "faq_pages", type: :feature, js: true do
  subject(:site) { cms_site }
  subject(:node) { create_once :faq_node_page, filename: "docs", name: "faq" }
  let!(:item2) { create(:faq_page, cur_node: node) }
  let!(:html) { "<p><a href=\"#{item2.url}\">関連記事リンク1</a></p>" }
  let!(:item3) { create(:faq_page, cur_node: node, html: html) }
  subject(:edit_path) { edit_faq_page_path site.id, node, item3 }
  subject(:edit_path2) { edit_faq_page_path site.id, node, item2 }

  before { login_cms_user }

  context "#draft_save" do
    let(:user) { cms_user }

    it "permited and contains_urls" do
      visit edit_path2
      wait_event_to_fire("ss:formAlertFinish") do
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
      end
      expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
    end

    it "permited and not contains_urls" do
      visit edit_path
      wait_event_to_fire("ss:formAlertFinish") do
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
      end
      expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
    end

    it "not permited and contains_urls" do
      role = user.cms_roles[0]
      role.update(permissions: %w(edit_private_faq_pages edit_other_faq_pages
                                  release_private_faq_pages release_other_faq_pages))
      visit edit_path2
      wait_event_to_fire("ss:formAlertFinish") do
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
      end
      expect(page).not_to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
      expect(page).to have_css(".errorExplanation", text: I18n.t('ss.confirm.contains_url_expect'))
    end

    it "not permited and not contains_urls" do
      role = user.cms_roles[0]
      role.update(permissions: %w(edit_private_faq_pages edit_other_faq_pages
                                  release_private_faq_pages release_other_faq_pages))
      visit edit_path
      wait_event_to_fire("ss:formAlertFinish") do
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
      end
      expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
    end
  end
end
