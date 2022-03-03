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
  let!(:page_item) { create :cms_page, form: form }

  before { login_cms_user }

  context 'stop deleting column whose form is in use without confirmation' do
    context "without confirmation" do
      it do
        visit cms_form_path(site: site, id: form)
        click_on I18n.t('cms.buttons.manage_columns')
        click_on column.name
        click_on I18n.t("ss.links.delete")

        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        message = I18n.t('errors.messages.unable_to_delete_in_use_column_without_confirmation')
        expect(page).to have_css('#errorExplanation', text: message)

        expect { column.reload }.not_to raise_error
      end
    end

    context "with confirmation" do
      it do
        visit cms_form_path(site: site, id: form)
        click_on I18n.t('cms.buttons.manage_columns')
        click_on column.name
        click_on I18n.t("ss.links.delete")

        within "form" do
          check "in_delete_confirmation"
          click_on I18n.t("ss.buttons.delete")
        end
        wait_for_notice I18n.t("ss.notice.deleted")

        expect { column.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      end
    end
  end

  context 'unable to delete all columns if form is in use' do
    it do
      visit cms_form_path(site: site, id: form)
      click_on I18n.t('cms.buttons.manage_columns')
      first(".list-head [type='checkbox']").click

      within ".list-head-action" do
        page.accept_confirm do
          click_on I18n.t("ss.links.delete")
        end
      end
      wait_for_notice I18n.t("errors.messages.unable_to_delete_all_columns_if_form_is_in_use")

      expect { column.reload }.not_to raise_error
    end
  end
end
