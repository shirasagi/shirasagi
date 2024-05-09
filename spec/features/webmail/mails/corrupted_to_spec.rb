require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "when corrupted to is given" do
    let(:user) { webmail_imap }
    # To の 2 つ目のメールアドレスが RFC 形式ではないうえに、UTF-8 として不正な文字（Ruby で例外を発生しうる文字）を含む
    let(:msg) { ::File.binread(Rails.root.join("spec/fixtures/webmail/corrupted_to.eml")) }

    before do
      webmail_import_mail(user, msg)
      Webmail.imap_pool.disconnect_all

      ActionMailer::Base.deliveries.clear
      login_user(user)
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    let(:index_path) { webmail_mails_path(account: 0) }

    it do
      visit index_path
      first("li.list-item").click
      expect(page).to have_css("#addon-basic .subject", text: "rspec-7c482a7f")
      expect(page).to have_css("#addon-basic .body--text", text: "test")
    end
  end
end
