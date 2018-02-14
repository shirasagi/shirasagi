require 'spec_helper'

describe 'article_pages', dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public') }
  let!(:column1) { create(:cms_column_text_field, cur_site: site, cur_form: form) }

  before do
    node.st_form_ids = [ form.id ]
    node.save!
  end

  context 'clone formed page' do
    let(:name) { unique_id }
    let(:column1_value) { unique_id }

    before { login_cms_user }

    it do
      visit new_article_page_path(site: site, cid: node, form_id: form.id)

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        fill_in "item[column_values][#{column1.id}]", with: column1_value
        click_on I18n.t('ss.buttons.publish_save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Article::Page.all.count).to eq 1

      visit article_pages_path(site: site, cid: node)
      click_on name
      click_on I18n.t('ss.links.copy')

      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Article::Page.all.count).to eq 2

      visit article_pages_path(site: site, cid: node)
      click_on "[#{I18n.t('workflow.cloned_name_prefix')}] #{name}"
      expect(page).to have_content(column1_value)
    end
  end
end
