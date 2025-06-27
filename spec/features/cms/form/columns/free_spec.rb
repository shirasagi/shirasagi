require 'spec_helper'

describe Cms::Form::ColumnsController, type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:form) { create(:cms_form, cur_site: site, sub_type: 'entry') }
  let(:name) { unique_id }
  let(:place_holder) { unique_id }

  before { login_cms_user }

  context 'basic crud' do
    it do
      visit cms_form_path(site, form)
      click_on I18n.t('cms.buttons.manage_columns')

      within '.gws-column-list-toolbar[data-placement="top"]' do
        click_on I18n.t('cms.columns.cms/free')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within '.gws-column-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item.name).to eq name
        expect(item.required).to eq 'required'
      end

      find('.btn-gws-column-item-detail').click
      within_dialog do
        fill_in 'item[place_holder]', with: place_holder
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item.name).to eq name
        expect(item.place_holder).to eq place_holder
      end

      page.accept_confirm do
        find('.btn-gws-column-item-delete').click
      end
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 0
    end
  end
end
