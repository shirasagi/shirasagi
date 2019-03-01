require 'spec_helper'

describe "gws_memo_messages", type: :feature, dbscope: :example do
  context "attached_file", js: true do
    before { create_gws_users }

    let(:sys) { Gws::User.find_by(uid: "sys") }
    let(:adm) { Gws::User.find_by(uid: "admin") }
    let(:user1) { Gws::User.find_by(uid: "user1") }
    let(:user2) { Gws::User.find_by(uid: "user2") }

    let(:site) { gws_site }

    let!(:memo) { create(:gws_memo_message, user: adm, site: site) }
    let!(:draft_memo) { create(:gws_memo_message, :with_draft, user: adm, site: site) }

    let(:logout_path) { gws_logout_path site }
    let(:edit_path) { edit_gws_memo_message_path(site: site, folder: 'INBOX.Draft', id: draft_memo.id) }

    def check_file(url)
      return false if current_path != url
      page.html.include?(url)
    end

    it "draft message's attached file" do
      user = adm

      login_user user
      visit edit_path

      ## attache file
      first('#addon-gws-agents-addons-file .ajax-box').click
      wait_for_cbox

      within "form.user-file" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_button "保存"
      end
      wait_for_ajax

      within "form#item-form" do
        click_button "保存"
      end

      ## check with login
      memo = Gws::Memo::Message.first
      memo.cur_site = site
      memo.cur_user = user
      fs_url = memo.files.first.url

      visit fs_url
      expect(check_file(fs_url)).to eq true

      ## check with logout
      visit logout_path

      visit fs_url
      expect(check_file(fs_url)).to eq false
    end

    it "sent message's attached file" do
      user = adm

      login_user user
      visit edit_path

      ## set member
      first('#addon-gws-agents-addons-memo-member .ajax-box').click
      wait_for_cbox
      click_on sys.name

      ## attache file
      first('#addon-gws-agents-addons-file .ajax-box').click
      wait_for_cbox

      within "form.user-file" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_button "保存"
      end
      wait_for_ajax

      within "form#item-form" do
        fill_in "item[subject]", with: "subject"
        click_button "送信"
      end
      page.driver.browser.switch_to.alert.accept
      wait_for_ajax

      ## check with login
      memo = Gws::Memo::Message.find_by(subject: "subject")
      memo.cur_site = site
      memo.cur_user = user
      fs_url = memo.files.first.url

      visit fs_url
      expect(check_file(fs_url)).to eq true

      ## check with logout
      visit logout_path

      visit fs_url
      expect(check_file(fs_url)).to eq false
    end
  end
end
