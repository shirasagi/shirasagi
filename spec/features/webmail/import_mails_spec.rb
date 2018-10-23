require 'spec_helper'

describe "webmail_import_mails", type: :feature, dbscope: :example, imap: true do
  before { login_webmail_imap }

  context "import from eml" do
    it do
      visit webmail_import_mails_path(account: 0)

      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/mail-1.eml"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("webmail.import.start_import"))

      visit webmail_mails_path(account: 0)
      expect(page).to have_css(".webmail-mails .field.title", text: "rspec-f5ttl71mhn")
    end
  end

  context "import from zip" do
    it do
      visit webmail_import_mails_path(account: 0)

      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/mail-2.zip"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("webmail.import.start_import"))

      visit webmail_mails_path(account: 0)
      expect(page).to have_css(".webmail-mails .field.title", text: "rspec-1ikzkezixu")
    end
  end
end
