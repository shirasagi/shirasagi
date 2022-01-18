require 'spec_helper'

describe Cms::Form::DbsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:name) { unique_id }
  let!(:form) { create(:cms_form, cur_site: site, sub_type: 'static') }
  let!(:col1) { create(:cms_column_select, cur_site: site, cur_form: form, order: 5) }
  let!(:col2) { create(:cms_column_radio_button, cur_site: site, cur_form: form, order: 6) }
  let!(:col3) { create(:cms_column_check_box, cur_site: site, cur_form: form, order: 7) }
  let!(:article_node) { create :article_node_page, cur_site: site }

  context 'basic crud' do
    before { login_cms_user }

    it do
      visit cms_form_dbs_path(site)
      click_on I18n.t('ss.links.new')

      # create
      within 'form#item-form' do
        fill_in 'item[name]', with: name
        select form.name, from: "item[form_id]"
        select article_node.name, from: "item[node_id]"
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # edit
      visit cms_form_dbs_path(site)
      click_on name
      click_on I18n.t('ss.links.edit')
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # delete
      click_on I18n.t('ss.links.delete')
      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      expect(Cms::FormDb.count).to eq 0
    end
  end
end
