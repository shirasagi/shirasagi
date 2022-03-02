require 'spec_helper'

describe Cms::Form::FormsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:form) { create :cms_form, cur_site: site, state: "public" }
  let!(:page_item) { create :cms_page, form: form }

  before { login_cms_user }

  context 'unable to close if form is in use' do
    it do
      visit cms_forms_path(site: site)
      click_on form.name
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.state.closed"), from: "item[state]"
        click_on I18n.t("ss.buttons.save")
      end
      within "form#item-form" do
        expect(page).to have_css('#errorExplanation', text: I18n.t('errors.messages.unable_to_close_form_if_form_is_in_use'))
      end
    end
  end

  context 'unable to delete form if form is in use' do
    it do
      visit cms_form_path(site: site, id: form)
      expect(page).to have_css(".nav-menu", text: I18n.t("ss.links.edit"))
      expect(page).to have_no_css(".nav-menu", text: I18n.t("ss.links.delete"))
      expect(page).to have_css(".nav-menu", text: I18n.t("ss.links.back_to_index"))
    end
  end

  context 'unable to delete form via delete_all if form is in use' do
    let!(:form2) { create :cms_form, cur_site: site, state: "public" }

    it do
      visit cms_forms_path(site: site)
      first(".list-head [type='checkbox']").click

      within ".list-head-action" do
        page.accept_confirm do
          click_on I18n.t("ss.links.delete")
        end
      end

      click_button I18n.t('ss.buttons.delete')

      wait_for_notice I18n.t("ss.notice.deleted")

      expect { form.reload }.not_to raise_error
      expect { form2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
