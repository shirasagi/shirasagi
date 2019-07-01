require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true do
  let(:user) { webmail_imap }

  before do
    ActionMailer::Base.deliveries.clear
    login_user(user)
  end

  it do
    visit webmail_mails_path(webmail_mode: 'account', account: user.imap_settings.length, mailbox: "INBOX")
    expect(page).to have_content(I18n.t("webmail.notice.imap_login_failed"))
  end

  it do
    expect do
      visit webmail_mails_path(webmail_mode: 'group', account: Webmail::Group.all.max(:id) + 1, mailbox: "INBOX")
    end.to raise_error Mongoid::Errors::DocumentNotFound
  end
end
