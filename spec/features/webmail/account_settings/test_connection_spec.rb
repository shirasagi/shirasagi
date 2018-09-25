require 'spec_helper'

describe "webmail_account_settings", type: :feature, dbscope: :example, imap: true, js: true do
  let(:user) { create :webmail_user }
  before { login_user(user) }

  context "test connection" do
    it do
      visit webmail_account_setting_path

      click_link I18n.t('ss.links.edit')
      first('.mod-webmail-account').click_button I18n.t('webmail.buttons.test_connection')
      expect(page).to have_css('.imap-test-resp', text: "Login Success.")
    end
  end
end
