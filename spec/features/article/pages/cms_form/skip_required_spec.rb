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
    end

    it "check saving as published" do 
      visit new_article_page_path(site: site, cid: node, form_id: form.id)

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.publish_save')
      end

      wait_for_ajax
      wait_for_error "登録内容を確認してください。次の項目を確認してください。#{column1.name}を入力してください。"
    end

    it "check saving as a draft and creating a branch page" do 
      visit new_article_page_path(site: site, cid: node, form_id: form.id)

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.draft_save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      find('input[value="差し替えページを作成する"]').click

      wait_for_ajax
      wait_for_error "登録内容を確認してください。次の項目を確認してください。#{column1.name}を入力してください。"
    end

    it "check saving as a draft and creating a approval request" do 
      visit new_article_page_path(site: site, cid: node, form_id: form.id)

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.draft_save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      click_link "選択"
      wait_for_ajax

      expect(page).to have_css(".workflow-partial-section")
      within(".workflow-partial-section") do 
        fill_in 'workflow[comment]', with: unique_id
        click_link "承認者を選択する"
      end

      wait_for_ajax
      expect(page).to have_css(".search-ui-form")

      within(".items") do 
        first('input[type="checkbox"][name="ids[]"]').click
      end

      wait_for_ajax
      expect(page).to have_css(".search-ui-select")

      within(".search-ui-select") do
        click_button "承認者を設定する"
      end

      wait_for_ajax

      within(".workflow-partial-section") do 
        click_button "申請"
      end

      wait_for_ajax
  
      expect( Article::Page.first.try(:workflow_state)).to eq nil
    end

  end
end