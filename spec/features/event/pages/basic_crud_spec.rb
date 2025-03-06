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
  subject(:delete_path2) { delete_event_page_path site.id, node, item2 }
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
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_on I18n.t("ss.links.input")
        fill_in "item[basename]", with: "sample"
        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      wait_for_turbo_frame '#workflow-branch-frame'
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
      wait_for_turbo_frame '#workflow-branch-frame'
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
    end

    it "#edit" do
      visit edit_path
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      wait_for_turbo_frame '#workflow-branch-frame'
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
    end

    it "#move" do
      visit move_path
      within "form#item-form" do
        fill_in "destination", with: "docs/destination"
        click_button I18n.t('ss.buttons.move')
      end
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form .current-filename", text: "docs/destination.html")

      within "form#item-form" do
        fill_in "destination", with: "docs/sample"
        click_button I18n.t('ss.buttons.move')
      end
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form .current-filename", text: "docs/sample.html")
    end

    it "#copy" do
      visit copy_path
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).to eq index_path
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_css("a", text: "[#{I18n.t('workflow.cloned_name_prefix')}] modify")
      expect(page).to have_css(".state", text: I18n.t("ss.state.edit"))
    end

    it "#delete" do
      visit delete_path
      expect(page).to have_css(".delete")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(current_path).to eq index_path
      wait_for_notice I18n.t('ss.notice.deleted')
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
      wait_for_notice I18n.t("ss.notice.started_import")

      expect(enqueued_jobs.length).to eq 1
      enqueued_jobs.first.tap do |enqueued_job|
        expect(enqueued_job[:job]).to eq Event::Page::ImportJob
        expect(enqueued_job[:args]).to be_present
        expect(enqueued_job[:args]).to have(1).items
        # file id
        expect(enqueued_job[:args][0]).to be_present
      end
    end
  end
end

describe "event_pages", type: :feature, dbscope: :example, js: true do
  subject(:site) { cms_site }
  subject(:node) { create_once :event_node_page, filename: "docs", name: "event" }
  let!(:item2) { create(:event_page, cur_node: node) }
  let!(:html) { "<p><a href=\"#{item2.url}\">関連記事リンク1</a></p>" }
  let!(:item3) { create(:event_page, cur_node: node, html: html) }
  subject(:edit_path) { edit_event_page_path site.id, node, item3 }
  subject(:edit_path2) { edit_event_page_path site.id, node, item2 }

  before { login_cms_user }

  context "#draft_save" do
    let(:user) { cms_user }

    it "permitted and contains_urls" do
      visit edit_path2
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        open_dialog I18n.t("ss.buttons.withdraw")
      end
      within_cbox do
        expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
      end
    end

    it "permitted and not contains_urls" do
      visit edit_path
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        open_dialog I18n.t("ss.buttons.withdraw")
      end
      within_cbox do
        expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
      end
    end

    it "not permitted and contains_urls" do
      role = user.cms_roles[0]
      role.update(permissions: %w(edit_private_event_pages edit_other_event_pages
                                  release_private_event_pages release_other_event_pages
                                  close_private_event_pages close_other_event_pages))
      visit edit_path2
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        click_on I18n.t("ss.buttons.withdraw")
      end
      expect(page).not_to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
      expect(page).to have_css(".errorExplanation", text: I18n.t('ss.confirm.contains_url_expect'))
    end

    it "not permitted and not contains_urls" do
      role = user.cms_roles[0]
      role.update(permissions: %w(edit_private_event_pages edit_other_event_pages
                                  release_private_event_pages release_other_event_pages
                                  close_private_event_pages close_other_event_pages))
      visit edit_path
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        open_dialog I18n.t("ss.buttons.withdraw")
      end
      within_cbox do
        expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
      end
    end
  end
end
