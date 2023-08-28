require 'spec_helper'

describe Cms::Form::FormsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:form) { create :cms_form, cur_site: site, state: "public" }
  let!(:column) do
    case rand(0..7)
    when 1
      create(:cms_column_date_field, cur_site: site, cur_form: form)
    when 2
      create(:cms_column_url_field, cur_site: site, cur_form: form)
    when 3
      create(:cms_column_text_area, cur_site: site, cur_form: form)
    when 4
      create(:cms_column_select, cur_site: site, cur_form: form)
    when 5
      create(:cms_column_radio_button, cur_site: site, cur_form: form)
    when 6
      create(:cms_column_check_box, cur_site: site, cur_form: form)
    when 7
      create(:cms_column_file_upload, cur_site: site, cur_form: form)
    else # 0
      create(:cms_column_text_field, cur_site: site, cur_form: form)
    end
  end
  let(:name) { "name/#{unique_id}" }

  before { login_cms_user }

  context 'with column_name_type is unrestricted' do
    around do |example|
      save_config = SS.config.replace_value_at(:cms, 'column_name_type', 'unrestricted')
      example.run
      SS.config.replace_value_at(:cms, 'column_name_type', save_config)
    end

    it do
      visit cms_form_path(site: site, id: form)
      click_on I18n.t('cms.buttons.manage_columns')
      click_on column.name
      click_on I18n.t("ss.links.edit")

      within "form" do
        fill_in "item[name]", with: name
        click_on I18n.t("ss.buttons.save")
      end

      expect(page).to have_css('dd', text: name)
      expect(page).to have_no_css('#errorExplanation')
    end
  end

  context 'with column_name_type is restricted' do
    around do |example|
      save_config = SS.config.replace_value_at(:cms, 'column_name_type', 'restricted')
      example.run
      SS.config.replace_value_at(:cms, 'column_name_type', save_config)
    end

    it do
      visit cms_form_path(site: site, id: form)
      click_on I18n.t('cms.buttons.manage_columns')
      click_on column.name
      click_on I18n.t("ss.links.edit")

      within "form" do
        fill_in "item[name]", with: name
        click_on I18n.t("ss.buttons.save")
      end

      expect(page).to have_no_css('dd', text: name)
      message = "#{column.t(:name)}#{I18n.t('errors.messages.invalid')}"
      expect(page).to have_css('#errorExplanation', text: message)
    end
  end
end
