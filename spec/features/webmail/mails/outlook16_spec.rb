require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "outlook16 mail corruption" do
    let(:user) { webmail_imap }
    let(:msg) { File.read(Rails.root.join("spec/fixtures/webmail/outlook16.eml")) }
    let(:index_path) { webmail_mails_path(account: 0) }

    before do
      webmail_import_mail(user, msg)
      Webmail.imap_pool.disconnect_all

      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it do
      login_user user, to: index_path

      first("li.list-item").click
      wait_for_js_ready
      expect(page).to have_css(".body--text", text: "テスト")
    end
  end
end
