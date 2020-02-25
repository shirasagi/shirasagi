require 'spec_helper'

describe 'article_pages', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let(:name) { unique_id }
  let!(:body_layout) { create(:cms_body_layout) }

  before do
    cms_role.add_to_set(permissions: %w(read_cms_body_layouts))
    node.st_form_ids = [ form.id ]
    node.save!
  end

  context 'basic crud with form' do
    before { login_cms_user }

    it do
      #
      # Create
      #
      visit new_article_page_path(site: site, cid: node)
      expect(page).to have_selector('#item_body_layout_id')
      expect(page).to have_selector('#item_form_id')

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        select body_layout.name, from: 'item[body_layout_id]'

        expect(page).to have_css("#addon-cms-agents-addons-body_part .addon-head", text: I18n.t('modules.addons.cms/body_part'))
        expect(page).to have_no_selector('#item_form_id', visible: true)

        select 'part1'
        page.execute_script(FILL_CKEDITOR_SCRIPT, find('#item_html_part_0'), '<p>part1</p>')
        select 'part2'
        page.execute_script(FILL_CKEDITOR_SCRIPT, find('#item_html_part_1'), '<p>part2</p>')
        select 'part3'
        page.execute_script(FILL_CKEDITOR_SCRIPT, find('#item_html_part_2'), '<p>part3</p>')

        click_on I18n.t('ss.buttons.draft_save')
      end
      click_on I18n.t('ss.buttons.ignore_alert')
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Article::Page.all.count).to eq 1
      Article::Page.all.first.tap do |item|
        expect(item.name).to eq name
        expect(item.body_parts).to eq ["<p>part1</p>\r\n", "<p>part2</p>\r\n", "<p>part3</p>\r\n"]
        expect(item.backups.count).to eq 1
      end

      #
      # Update
      #
      visit article_pages_path(site: site, cid: node)
      expect(page).to have_no_selector('#item_form_id', visible: true)

      click_on name
      click_on I18n.t('ss.links.edit')
      within 'form#item-form' do
        select 'part1'
        page.execute_script(FILL_CKEDITOR_SCRIPT, find('#item_html_part_0'), '<p>part4</p>')
        select 'part2'
        page.execute_script(FILL_CKEDITOR_SCRIPT, find('#item_html_part_1'), '<p>part5</p>')
        select 'part3'
        page.execute_script(FILL_CKEDITOR_SCRIPT, find('#item_html_part_2'), '<p>part6</p>')

        click_on I18n.t('ss.buttons.draft_save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Article::Page.all.count).to eq 1
      Article::Page.all.first.tap do |item|
        expect(item.name).to eq name
        expect(item.body_parts).to eq ["<p>part4</p>\r\n", "<p>part5</p>\r\n", "<p>part6</p>\r\n"]
        expect(item.backups.count).to eq 2
      end

      #
      # Delete
      #
      visit article_pages_path(site: site, cid: node)
      click_on name
      click_on I18n.t('ss.links.delete')
      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      expect(Article::Page.all.count).to eq 0
    end
  end
end
