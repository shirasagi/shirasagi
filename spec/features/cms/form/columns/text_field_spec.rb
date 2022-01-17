require 'spec_helper'

describe Cms::Form::ColumnsController, type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:form) { create(:cms_form, cur_site: site, sub_type: 'static') }
  let(:name) { unique_id }

  before { login_cms_user }

  context 'with text' do
    it do
      #
      # Create
      #
      visit cms_form_path(site, form)
      click_on I18n.t('cms.buttons.manage_columns')
      click_on I18n.t('ss.links.new')
      click_on I18n.t('cms.columns.cms/text_field')

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        select I18n.t('cms.options.column_input_type.text'), from: 'item[input_type]'
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 1
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item.name).to eq name
        expect(item.required).to eq 'required'
        expect(item.input_type).to eq 'text'
      end

      #
      # Read & Update
      #
      visit cms_form_columns_path(site, form)
      click_on name
      click_on I18n.t('ss.links.edit')
      within 'form#item-form' do
        select I18n.t('ss.options.state.optional'), from: 'item[required]'
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 1
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item.name).to eq name
        expect(item.required).to eq 'optional'
        expect(item.input_type).to eq 'text'
      end

      #
      # Delete
      #
      visit cms_form_columns_path(site, form)
      click_on name
      click_on I18n.t('ss.links.delete')
      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 0
    end
  end

  context 'with email' do
    it do
      #
      # Create
      #
      visit cms_form_path(site, form)
      click_on I18n.t('cms.buttons.manage_columns')
      click_on I18n.t('ss.links.new')
      click_on I18n.t('cms.columns.cms/text_field')

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        select I18n.t('cms.options.column_input_type.email'), from: 'item[input_type]'
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 1
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item.name).to eq name
        expect(item.required).to eq 'required'
        expect(item.input_type).to eq 'email'
      end

      #
      # Read & Update
      #
      visit cms_form_columns_path(site, form)
      click_on name
      click_on I18n.t('ss.links.edit')
      within 'form#item-form' do
        select I18n.t('ss.options.state.optional'), from: 'item[required]'
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 1
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item.name).to eq name
        expect(item.required).to eq 'optional'
        expect(item.input_type).to eq 'email'
      end

      #
      # Delete
      #
      visit cms_form_columns_path(site, form)
      click_on name
      click_on I18n.t('ss.links.delete')
      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 0
    end
  end

  context 'with tel' do
    it do
      #
      # Create
      #
      visit cms_form_path(site, form)
      click_on I18n.t('cms.buttons.manage_columns')
      click_on I18n.t('ss.links.new')
      click_on I18n.t('cms.columns.cms/text_field')

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        select I18n.t('cms.options.column_input_type.tel'), from: 'item[input_type]'
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 1
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item.name).to eq name
        expect(item.required).to eq 'required'
        expect(item.input_type).to eq 'tel'
      end

      #
      # Read & Update
      #
      visit cms_form_columns_path(site, form)
      click_on name
      click_on I18n.t('ss.links.edit')
      within 'form#item-form' do
        select I18n.t('ss.options.state.optional'), from: 'item[required]'
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 1
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item.name).to eq name
        expect(item.required).to eq 'optional'
        expect(item.input_type).to eq 'tel'
      end

      #
      # Delete
      #
      visit cms_form_columns_path(site, form)
      click_on name
      click_on I18n.t('ss.links.delete')
      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 0
    end
  end
end
