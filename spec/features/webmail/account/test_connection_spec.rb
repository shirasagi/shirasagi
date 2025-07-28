require 'spec_helper'

describe "webmail_account", type: :feature, dbscope: :example, imap: true, js: true do
  before { login_webmail_imap }

  context "test connection" do
    it do
      visit webmail_account_path(account: 0)
      click_on I18n.t('ss.links.edit')
      wait_for_js_ready

      within "form#item-form" do
        click_on I18n.t('webmail.buttons.test_connection')
      end

      expect(page).to have_css('.imap-test-resp', text: "Login Success.")
    end
  end
end
