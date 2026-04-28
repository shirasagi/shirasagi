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
        wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/headline') }
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

      wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }
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

  context 'min/max headline level configuration' do
    it 'creates a new column with h2/h4 defaults and allows updating to h3/h6' do
      visit cms_form_path(site, form)
      click_on I18n.t('cms.buttons.manage_columns')

      within '.gws-column-list-toolbar[data-placement="top"]' do
        wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/headline') }
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within '.gws-column-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # new-default (h2/h4) must be persisted for a newly created column
      created = Cms::Column::Base.site(site).where(form_id: form.id).first
      expect(created.min_headline_level).to eq 'h2'
      expect(created.max_headline_level).to eq 'h4'

      wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }
      within_dialog do
        expect(page).to have_select('item[min_headline_level]', selected: 'h2')
        expect(page).to have_select('item[max_headline_level]', selected: 'h4')
        select 'h3', from: 'item[min_headline_level]'
        select 'h6', from: 'item[max_headline_level]'
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      updated = Cms::Column::Base.site(site).where(form_id: form.id).first
      expect(updated.min_headline_level).to eq 'h3'
      expect(updated.max_headline_level).to eq 'h6'
      expect(updated.headline_list.values).to eq %w(h3 h4 h5 h6)
    end

    it 'rejects min/max options that are not h2..h6 (h1 is not offered)' do
      visit cms_form_path(site, form)
      click_on I18n.t('cms.buttons.manage_columns')

      within '.gws-column-list-toolbar[data-placement="top"]' do
        wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/headline') }
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within '.gws-column-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }
      within_dialog do
        min_options = all('select[name="item[min_headline_level]"] option').map(&:value)
        max_options = all('select[name="item[max_headline_level]"] option').map(&:value)
        expect(min_options).to eq %w(h2 h3 h4 h5 h6)
        expect(max_options).to eq %w(h2 h3 h4 h5 h6)
      end
    end
  end
end
