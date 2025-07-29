require 'spec_helper'

describe Cms::Form::InitColumnsController, type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:form) { create(:cms_form, cur_site: site, sub_type: 'entry') }
  let!(:column) { create(:cms_column_text_field, cur_form: form, cur_site: site) }

  before { login_cms_user }

  context 'basic crud' do
    it do
      visit cms_form_path(site, form)
      click_on I18n.t('cms.buttons.manage_init_columns')

      within '.gws-column-list-toolbar[data-placement="top"]' do
        click_on column.name
      end
      wait_for_notice I18n.t('ss.notice.saved')

      page.accept_confirm do
        find('.btn-gws-column-item-delete').click
      end
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(Cms::InitColumn.site(site).where(form_id: form.id).count).to eq 0
    end
  end

  context 'when column is destroyed' do
    it do
      visit cms_form_path(site, form)
      click_on I18n.t('cms.buttons.manage_init_columns')

      within '.gws-column-list-toolbar[data-placement="top"]' do
        click_on column.name
      end
      wait_for_notice I18n.t('ss.notice.saved')

      column.destroy

      visit cms_form_init_columns_path(site, form)
      expect(page).to have_no_css('.gws-column-item', text: column.name)
    end
  end

  context 'when column is unset' do
    it do
      visit cms_form_path(site, form)
      click_on I18n.t('cms.buttons.manage_init_columns')

      within '.gws-column-list-toolbar[data-placement="top"]' do
        click_on column.name
      end
      wait_for_notice I18n.t('ss.notice.saved')

      Cms::InitColumn.form(form).first.unset(:column_id)

      visit cms_form_init_columns_path(site, form)
      expect(page).to have_css('.gws-column-item .header', text: I18n.t('cms.init_column.not_found_column'))

      page.accept_confirm do
        find('.btn-gws-column-item-delete').click
      end
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(Cms::InitColumn.site(site).where(form_id: form.id).count).to eq 0
    end
  end
end
