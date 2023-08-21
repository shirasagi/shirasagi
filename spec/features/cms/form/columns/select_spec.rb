require 'spec_helper'

describe Cms::Form::ColumnsController, type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:form) { create(:cms_form, cur_site: site, sub_type: 'static') }
  let(:name) { unique_id }
  let(:select_options) { [ unique_id, unique_id, unique_id ] }

  before { login_cms_user }

  context 'basic crud' do
    it do
      #
      # Create
      #
      visit cms_form_path(site, form)
      click_on I18n.t('cms.buttons.manage_columns')
      click_on I18n.t('ss.links.new')
      click_on I18n.t('cms.columns.cms/select')

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        fill_in 'item[select_options]', with: select_options.join("\n")
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 1
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item.name).to eq name
        expect(item.required).to eq 'required'
        expect(item.select_options).to eq select_options
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
        expect(item.select_options).to eq select_options
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
