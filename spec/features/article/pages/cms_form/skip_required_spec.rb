require 'spec_helper'

describe 'article_pages', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let!(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, input_type: 'text', required: "required")
  end

  let(:name) { unique_id }

  before do
    node.st_form_ids = [ form.id ]
    node.save!
  end

  context "Check saving a new page in different ways with empty required form values" do 
    before { login_cms_user }

    it "check saving as a draft" do 
      visit new_article_page_path(site: site, cid: node, form_id: form.id)

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.draft_save')
      end

      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      wait_for_turbo_frame "#workflow-branch-frame"
    end

    it "check saving as published" do 
      visit new_article_page_path(site: site, cid: node, form_id: form.id)

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.publish_save')
      end

      wait_for_all_ckeditors_ready
      msg = I18n.t("errors.messages.blank")
      msg = I18n.t("errors.format", attribute: column1.name, message: msg)
      wait_for_error msg
    end

    it "check saving as a draft and creating a branch page" do 
      visit new_article_page_path(site: site, cid: node, form_id: form.id)

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.draft_save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      wait_for_turbo_frame "#workflow-branch-frame"
      wait_event_to_fire "turbo:frame-load" do
        click_on I18n.t("workflow.create_branch")
      end

      wait_for_ajax
      msg = I18n.t("errors.messages.blank")
      msg = I18n.t("errors.format", attribute: column1.name, message: msg)
      wait_for_error msg
    end

    it "check saving as a draft and creating a approval request" do 
      visit new_article_page_path(site: site, cid: node, form_id: form.id)

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.draft_save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      wait_for_turbo_frame "#workflow-branch-frame"
      click_link I18n.t("workflow.buttons.select")
      wait_for_ajax

      expect(page).to have_css(".workflow-partial-section")
      within(".workflow-partial-section") do 
        fill_in 'workflow[comment]', with: unique_id
        wait_for_cbox_opened { click_link I18n.t("workflow.search_approvers.index") }
      end

      wait_for_ajax
      expect(page).to have_css(".search-ui-form")

      within_cbox do
        within(".items") do
          first('input[type="checkbox"][name="ids[]"]').click
        end

        wait_for_ajax
        expect(page).to have_css(".search-ui-select")

        within(".search-ui-select") do
          wait_for_cbox_closed { click_button I18n.t("workflow.search_approvers.select") }
        end
      end

      wait_for_ajax

      within(".workflow-partial-section") do 
        click_button I18n.t("workflow.buttons.request")
      end

      wait_for_ajax

      msg = I18n.t("errors.messages.blank")
      msg = I18n.t("errors.format", attribute: column1.name, message: msg)
      page.accept_alert(msg)
  
      expect( Article::Page.first.try(:workflow_state)).to eq nil
    end

  end
end