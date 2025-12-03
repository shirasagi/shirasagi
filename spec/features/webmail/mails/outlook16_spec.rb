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

      click_on "件名テスト"
      wait_for_js_ready
      expect(page).to have_css(".subject", text: "件名テスト")
      expect(page).to have_css(".from", text: "差出人テスト")
      expect(page).to have_css(".address-field", text: "宛先テスト")
      expect(page).to have_css(".body--text", text: "本文テスト")
    end
  end
end
