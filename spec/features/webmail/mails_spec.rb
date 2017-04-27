require 'spec_helper'

describe "webmail_mails", imap: true, type: :feature, dbscope: :example do
  let(:user) { create :webmail_user }
  let(:mail_title) { "rspec-test" }
  let(:index_path) { webmail_mails_path }
  let(:new_path) { "#{index_path}/new" }

  context "with auth" do
    before do
      login_user user
    end

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[to_text]", with: user.email
        fill_in "item[subject]", with: mail_title
        fill_in "item[text]", with: "message\n" * 2
        click_button "送信"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit index_path
      click_on mail_title
      expect(status_code).to eq 200
    end
  end
end
