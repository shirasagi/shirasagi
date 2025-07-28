require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:filename) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let(:file) { tmp_ss_file(site: site, user: cms_user, contents: filename) }
  let!(:master_page) { create(:article_page, cur_site: site, cur_node: node, cur_user: cms_user) }
  let!(:branch_page) do
    master_page.cur_node = node

    copy = master_page.new_clone
    copy.master = master_page
    copy.html = "#{copy.html}\n<img src=\"#{file.url}\" alt=\"#{file.humanized_name}\">"
    copy.file_ids = Array(copy.file_ids) + [ file.id ]
    copy.save!

    master_page.reload
    file.reload

    Article::Page.find(copy.id)
  end

  let(:index_path) { article_pages_path site.id, node }
  let(:show_path) { article_page_path site.id, node, master_page }
  let(:contains_urls_path) { contains_urls_article_page_path site.id, node, master_page }

  context "Try and delete replacement pages but you can't" do
    before do 
      branch_page.update(related_page_ids: [master_page.id])
      master_page.reload
      branch_page.reload
      login_cms_user
    end

    it "Hit index and try to delete with delete_alert_disabled" do
      role = cms_role
      role.update(permissions: (role.permissions - %w(delete_cms_ignore_alert)))
      role.reload

      visit index_path
      expect(page).to have_css(".list-items")

      within ".list-items" do 
        expect(page).to have_css("input[type='checkbox'][value='#{master_page.id}']")
        expect(page).to have_css("input[type='checkbox'][value='#{branch_page.id}']")
        find("input[type='checkbox'][value='#{master_page.id}']").click
        find("input[type='checkbox'][value='#{branch_page.id}']").click
        expect(find("input[type='checkbox'][value='#{master_page.id}']")).to be_checked
        expect(find("input[type='checkbox'][value='#{branch_page.id}']")).to be_checked
      end
      find('.destroy-all').click
      wait_for_js_ready

      contains_urls = Cms::Page.site(site).and_linking_pages(master_page)
      delete_alert_enabled = cms_user.cms_role_permit_any?(site, %w(delete_cms_ignore_alert)) && contains_urls.present?
      expect(contains_urls.present? && delete_alert_enabled).to eq false

      expect(page).to have_css("h2", text: I18n.t("ss.confirm.target_to_delete"))
      expect(page).to have_css("input[type='checkbox'][value='#{branch_page.id}'][checked='checked']")
      expect(page).to_not have_css("input[type='checkbox'][value='#{master_page.id}'][checked='checked']")
      expect(page).to have_content(I18n.t("ss.confirm.unable_to_delete_due_to_branch_page"))
      expect(page).to_not have_content(I18n.t("ss.confirm.contains_links_in_file_ignoring_alert"))
    end

    it "Hit index and try to delete without delete_alert_disabled" do
      role = cms_role
      role.update(permissions: (role.permissions + %w(delete_cms_ignore_alert)))
      role.reload

      contains_urls = Cms::Page.site(site).and_linking_pages(master_page)
      delete_alert_enabled = cms_user.cms_role_permit_any?(site, %w(delete_cms_ignore_alert)) && contains_urls.present?
      expect(contains_urls.present? && delete_alert_enabled).to eq true

      visit index_path
      expect(page).to have_css(".list-items")

      within ".list-items" do 
        expect(page).to have_css("input[type='checkbox'][value='#{master_page.id}']")
        expect(page).to have_css("input[type='checkbox'][value='#{branch_page.id}']")
        find("input[type='checkbox'][value='#{master_page.id}']").click
        find("input[type='checkbox'][value='#{branch_page.id}']").click
        expect(find("input[type='checkbox'][value='#{master_page.id}']")).to be_checked
        expect(find("input[type='checkbox'][value='#{branch_page.id}']")).to be_checked
      end
      find('.destroy-all').click
      wait_for_ajax
      expect(page).to have_css("h2", text: I18n.t("ss.confirm.target_to_delete"))

      # master page
      within "[data-id='#{master_page.id}']" do
        # master page unable to delete.
        # If the master page is deleted, the relationship in the database becomes inconsistent,
        # causing unrecoverable problems with the operation on the branch page.
        expect(page).to have_no_css("[type='checkbox']")
        expect(page).to have_content(I18n.t("ss.confirm.unable_to_delete_due_to_branch_page"))
      end

      # branch page
      within "[data-id='#{branch_page.id}']" do
        # branch page is always safe to delete.
        contains_urls = Cms::Page.site(site).and_linking_pages(branch_page)
        delete_alert_enabled = cms_user.cms_role_permit_any?(site, %w(delete_cms_ignore_alert)) && contains_urls.present?
        expect(contains_urls.present? && delete_alert_enabled).to eq false
        expect(page).to have_css("[type='checkbox']")
        if delete_alert_enabled
          expect(page).to have_content(I18n.t("ss.confirm.contains_links_in_file_ignoring_alert"))
        else
          expect(page).to have_content(I18n.t("ss.confirm.contains_links_in_file"))
        end
      end
    end
  end
end