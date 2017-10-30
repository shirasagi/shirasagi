require 'spec_helper'

describe "webmail_filters", type: :feature, dbscope: :example, imap: true do
  let(:user) { create :webmail_user }
  let(:item_title) { "rspec-#{unique_id}" }
  let(:index_path) { webmail_filters_path(account: 0) }

  context "with auth" do
    before { login_user(user) }

    it "#index", js: true do
      visit index_path

      # new/create
      click_link I18n.t('ss.links.new')
      within "form#item-form" do
        fill_in "item[name]", with: item_title
        fill_in "item[from]", with: item_title
        select I18n.t('webmail.box.inbox'), from: "item[mailbox]"
        #find("option[value='INBOX']").select_option
      end
      click_button I18n.t('ss.buttons.save')
      click_link I18n.t('ss.links.back_to_index')

      # edit/update
      click_link item_title
      click_link I18n.t('ss.links.edit')
      click_button I18n.t('ss.buttons.save')

      # apply filter
      find(".apply-mailbox option[value='INBOX']").select_option
      find(".apply-filter").click
      page.accept_confirm

      # delete/destroy
      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')

      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end
  end
end
