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

  context "when collapsed multipart message is given" do
    it do
      visit webmail_import_mails_path(account: 0)

      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/collapsed-multipart.eml"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("webmail.import.start_import"))

      visit webmail_mails_path(account: 0)
      expect(page).to have_css(".webmail-mails .field.title", text: "rspec-f5ttl71mhn")
    end
  end

  context "when a zip file contains too large eml" do
    before do
      @save = Webmail::MailImporter::MAX_MAIL_SIZE
      Webmail::MailImporter.send(:remove_const, "MAX_MAIL_SIZE")
      Webmail::MailImporter.const_set("MAX_MAIL_SIZE", 1)
    end

    after do
      Webmail::MailImporter.send(:remove_const, "MAX_MAIL_SIZE")
      Webmail::MailImporter.const_set("MAX_MAIL_SIZE", @save)
      expect(Webmail::MailImporter::MAX_MAIL_SIZE).to eq @save
    end

    it do
      visit webmail_import_mails_path(account: 0)

      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/mail-2.zip"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css('#errorExplanation', text: "サイズが大きすぎます")
    end
  end
end
