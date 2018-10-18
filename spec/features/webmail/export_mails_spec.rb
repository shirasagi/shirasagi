require 'spec_helper'

describe "webmail_export_mails", type: :feature, dbscope: :example, imap: true, js: true do
  let(:mail1) do
    Mail.new do
      from "from-#{unique_id}@example.jp"
      to "to-#{unique_id}@example.jp"
      subject "subject-#{unique_id}"
      body "message-#{unique_id}\nmessage-#{unique_id}"
    end
  end
  let(:mail2) do
    Mail.new do
      from "from-#{unique_id}@example.jp"
      to "to-#{unique_id}@example.jp"
      subject "subject-#{unique_id}"
      body "message-#{unique_id}\nmessage-#{unique_id}"
    end
  end
  let(:mail3) do
    Mail.new do
      from "from-#{unique_id}@example.jp"
      to "to-#{unique_id}@example.jp"
      subject "subject-#{unique_id}"
      body "message-#{unique_id}\nmessage-#{unique_id}"
    end
  end

  before do
    webmail_import_mail(webmail_imap, mail1)
    webmail_import_mail(webmail_imap, mail2)
    webmail_import_mail(webmail_imap, mail3)

    login_webmail_imap
  end

  context "export all mails" do
    it do
      visit webmail_export_mails_path(account: 0)
      within "form#item-form" do
        choose "item_all_export_all"
        click_on I18n.t("ss.export")
      end

      expect(page).to have_content("ダウンロードの準備が完了しました。")
    end
  end

  context "export selected mails" do
    it do
      visit webmail_export_mails_path(account: 0)
      within "form#item-form" do
        choose "item_all_export_select"
        click_on I18n.t("ss.links.select")
      end
      within "#cboxLoadedContent" do
        expect(page).to have_content(mail1.subject)
        expect(page).to have_content(mail3.subject)
        click_on mail2.subject
      end
      within "form#item-form" do
        click_on I18n.t("ss.export")
      end

      expect(page).to have_content("ダウンロードの準備が完了しました。")
    end
  end
end
