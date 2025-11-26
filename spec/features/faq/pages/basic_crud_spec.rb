require 'spec_helper'

describe "faq_pages", type: :feature, js: true do
  let!(:site) { cms_site }
  let!(:node) { create :faq_node_page, cur_site: site }

  context "basic crud" do
    let(:index_path) { faq_pages_path site.id, node }

    it do
      login_cms_user to: index_path

      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_on I18n.t("ss.links.input")
        fill_in "item[basename]", with: "sample"
        fill_in_ckeditor "item[question]", with: "<p>question</p>"
        fill_in_ckeditor "item[html]", with: "<p>body</p>"
        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      click_on I18n.t("ss.links.edit")
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        fill_in_ckeditor "item[question]", with: "<p>modified question</p>"
        fill_in_ckeditor "item[html]", with: "<p>modified body</p>"
        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      click_on I18n.t("ss.links.delete")
      expect(page).to have_css(".delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')
    end
  end

  describe "#move" do
    let!(:item) { create :faq_page, cur_site: site, cur_node: node }
    let(:move_path) { move_faq_page_path site.id, node, item }

    it do
      login_cms_user to: move_path
      within "form" do
        fill_in "destination", with: "#{node.filename}/destination"
        click_button I18n.t('ss.buttons.move')
      end
      wait_for_notice I18n.t('ss.notice.moved')
      expect(page).to have_css("form#item-form .current-filename", text: "#{node.filename}/destination.html")
      expect(current_path).to eq move_path

      within "form" do
        fill_in "destination", with: "#{node.filename}/sample"
        click_button I18n.t('ss.buttons.move')
      end
      wait_for_notice I18n.t('ss.notice.moved')
      expect(page).to have_css("form#item-form .current-filename", text: "#{node.filename}/sample.html")
      expect(current_path).to eq move_path
    end
  end

  describe "#copy" do
    let!(:item) { create :faq_page, cur_site: site, cur_node: node }
    let(:copy_path) { copy_faq_page_path site.id, node, item }

    it do
      login_cms_user to: copy_path
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("a", text: "[#{I18n.t('workflow.cloned_name_prefix')}] #{item.name}")
      expect(page).to have_css(".state", text: I18n.t("ss.state.edit"))
    end
  end

  describe "#contains_urls" do
    let!(:item) { create :faq_page, cur_site: site, cur_node: node }
    let(:contains_urls_path) { contains_urls_faq_page_path site.id, node, item }

    it do
      login_cms_user to: contains_urls_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end
  end

  describe "#import" do
    let(:import_path) { import_faq_pages_path site.id, node }

    it do
      login_cms_user to: import_path

      within "form#task-form" do
        attach_file "item[file]", "#{Rails.root}/spec/fixtures/faq/import_job/faq_pages.csv"
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end
      expect(page).to have_content I18n.t("ss.notice.started_import")
    end
  end

  context "#draft_save" do
    let(:user) { cms_user }
    let!(:item2) { create(:faq_page, cur_site: site, cur_node: node) }
    let!(:html) { "<p><a href=\"#{item2.url}\">関連記事リンク1</a></p>" }
    let!(:item3) { create(:faq_page, cur_site: site, cur_node: node, html: html) }
    let(:edit_path) { edit_faq_page_path site.id, node, item3 }
    let(:edit_path2) { edit_faq_page_path site.id, node, item2 }

    before { login_cms_user }

    it "permited and contains_urls" do
      visit edit_path2
      wait_for_event_fired("ss:formAlertFinish") do
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
      end
      expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
    end

    it "permited and not contains_urls" do
      visit edit_path
      wait_for_event_fired("ss:formAlertFinish") do
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
      end
      expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
    end

    it "not permited and contains_urls" do
      role = user.cms_roles[0]
      role.update(permissions: %w(edit_private_faq_pages edit_other_faq_pages
                                  release_private_faq_pages release_other_faq_pages
                                  close_private_faq_pages close_other_faq_pages))
      visit edit_path2
      wait_for_event_fired("ss:formAlertFinish") do
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
                                  release_private_faq_pages release_other_faq_pages
                                  close_private_faq_pages close_other_faq_pages))
      visit edit_path
      wait_for_event_fired("ss:formAlertFinish") do
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
      end
      expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
    end
  end
end
