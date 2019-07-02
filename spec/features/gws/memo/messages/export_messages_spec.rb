require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:memo) { create(:gws_memo_message, user: user, site: site) }
  let!(:draft_memo) { create(:gws_memo_message, :with_draft, user: user, site: site) }

  describe 'export' do
    before { login_gws_user }

    it do
      visit gws_memo_export_messages_path(site)
      within "form#item-form" do
        select 'eml', from: 'item_format'
        click_on I18n.t("ss.links.select")
      end
      within "#cboxLoadedContent" do
        expect(page).to have_css(".list-item", text: memo.subject)
        click_on memo.subject
      end
      within "form#item-form" do
        click_on I18n.t("ss.export")
      end

      expect(page).to have_css("#notice", text: I18n.t("gws/memo/message.notice.start_export"))
      within '#addon-basic' do
        expect(page).to have_content(I18n.t("gws/memo/message.export.start_message").split("\n").first)
      end

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))
      end

      page.execute_script("SS.clearNotice();")

      within "nav.user" do
        first(".gws-memo-notice.popup-notice-container a").click

        within ".popup-notice-items .list-item.unseen" do
          click_on I18n.t("gws/memo/message.export.subject")
        end
      end

      within ".gws-memo-notices .body" do
        expect(page).to have_content(I18n.t("gws/memo/message.export.notify_message", link: "").split("\n").first)
        expect(page).to have_link(href: /\.zip$/)
        first("a").click
      end

      wait_for_download
      names = []
      mails = []
      Zip::File.open(downloads.first) do |zip_file|
        zip_file.each do |entry|
          names << NKF.nkf("-w", entry.name)
          mails << ::Mail.read_from_string(entry.get_input_stream.read)
        end
      end
      expect(names).to have(1).items
      expect(names).to include(include(memo.subject))
      mails.first.tap do |mail|
        expect(mail.message_id).to be_nil
        expect(mail.sender).to be_nil
        expect(mail[:from].to_s).to eq "#{memo.from.name} <#{memo.from.email}>"
        expect(mail[:to].to_s).to eq memo.to_members.map { |u| "#{u.name} <#{u.email}>" }.join(", ")
        expect(mail[:cc]).to be_nil
        expect(mail[:bcc]).to be_nil
        expect(mail[:reply_to]).to be_nil
        expect(mail["X-Shirasagi-Status"].decoded).to eq "未読"
        expect(mail.in_reply_to).to be_nil
        expect(mail.references).to be_nil
        expect(mail.subject).to eq memo.subject
        expect(mail.mime_type).to eq "text/plain"
        expect(mail.multipart?).to be_falsey
        expect(mail.parts).to be_blank
        expect(mail.body.decoded).to include(memo.text)
      end
    end
  end
end
