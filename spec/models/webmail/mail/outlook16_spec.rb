require 'spec_helper'

describe Webmail::Mail, type: :model, dbscope: :example, imap: true do
  context "outlook16 mail corruption" do
    let(:user) { webmail_imap }
    let(:account) { 0 }
    let(:imap) { user.initialize_imap(account) }
    let(:mailbox) { "INBOX" }
    let(:msg) { File.read(Rails.root.join("spec/fixtures/webmail/outlook16.eml")) }

    before do
      webmail_import_mail(user, msg)
      Webmail.imap_pool.disconnect_all

      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
      Webmail.imap_pool.disconnect_all
    end

    it do
      webmail_imap_login = imap.login
      expect(webmail_imap_login).to be_truthy

      imap.examine(mailbox)
      items = imap.mails.mailbox(mailbox).all
      item = imap.mails.find(items[0].uid, :body)
      expect(item.display_subject).to include("テスト")
      expect(item.text).to include("テスト")
    end
  end
end
