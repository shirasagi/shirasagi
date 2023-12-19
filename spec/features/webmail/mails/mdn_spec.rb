require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  let!(:user) { webmail_imap }
  let!(:mailbox) { nil }
  let(:now) { Time.zone.now.change(usec: 0) }

  shared_examples "mdn reply" do
    before do
      webmail_import_mail(webmail_imap, mdn_mail, mailbox: mailbox ? mailbox.original_name : 'INBOX')
      login_user user
    end

    it do
      visit index_path
      if mailbox
        within ".main-navi .mailboxes" do
          click_on mailbox.name
        end
      end
      click_on mdn_mail.subject
      wait_for_js_ready
      Timecop.freeze(now) do
        within ".request-mdn-notice" do
          expect(page).to have_css(".message", text: I18n.t("webmail.notice.requested_mdn"))
          click_on I18n.t("webmail.buttons.send_mdn")
        end
        wait_for_notice I18n.t("webmail.notice.send_mdn")
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.first.tap do |mdn_reply_mail|
        expect(mdn_reply_mail.from.first).to eq mdn_mail.to.first
        expect(mdn_reply_mail.to.first).to eq mdn_mail[:disposition_notification_to].to_s
        expect(mdn_reply_mail.subject).to eq "開封済み：#{mdn_mail.subject}"
        expect(mdn_reply_mail.body.multipart?).to be_truthy
        expect(mdn_reply_mail.parts.length).to eq 3
        mdn_reply_mail.parts[0].tap do |part|
          expect(part.content_type).to include("text/plain")
          body = part.body.raw_source.encode("UTF-8", "iso-2022-jp")
          expect(body).to include(mdn_mail.to.first, "メッセージが開封されました。", I18n.l(now, format: :picker))
        end
        mdn_reply_mail.parts[1].tap do |part|
          expect(part.content_type).to include("message/disposition-notification")
        end
        mdn_reply_mail.parts[2].tap do |part|
          expect(part.content_type).to include("text/rfc822-headers")
        end
      end
    end
  end

  describe "webmail_mode is account" do
    let(:account) { 0 }
    let!(:imap) { user.initialize_imap(account) }
    let!(:mdn_mail) do
      Mail.new(
        from: "from-#{unique_id}@example.jp",
        to: imap.address,
        subject: "subject-#{unique_id}",
        disposition_notification_to: "from-#{unique_id}@example.jp",
        body: "message-#{unique_id}\nmessage-#{unique_id}"
      )
    end

    context "within INBOX" do
      let(:index_path) { webmail_mails_path(account: account) }

      it_behaves_like "mdn reply"
    end

    context "within a mailbox" do
      let!(:mailbox) do
        mailbox = Webmail::Mailbox.new(name: unique_id)
        mailbox.attributes = imap.account_scope.merge(cur_user: user, imap: imap, sync: true)
        mailbox.save!

        imap.login
        mailbox.imap_create

        mailbox
      end
      let(:index_path) { webmail_mails_path(account: account) }

      it_behaves_like "mdn reply"
    end
  end

  describe "webmail_mode is group" do
    let!(:group) { create :webmail_group }
    let!(:imap) { group.initialize_imap }
    let!(:mdn_mail) do
      Mail.new(
        from: "from-#{unique_id}@example.jp",
        to: imap.address,
        subject: "subject-#{unique_id}",
        disposition_notification_to: "from-#{unique_id}@example.jp",
        body: "message-#{unique_id}\nmessage-#{unique_id}"
      )
    end

    before { user.add_to_set(group_ids: [ group.id ]) }

    context "within INBOX" do
      let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }
      it_behaves_like "mdn reply"
    end

    context "within a mailbox" do
      let!(:mailbox) do
        mailbox = Webmail::Mailbox.new(name: unique_id)
        mailbox.attributes = imap.account_scope.merge(cur_user: user, imap: imap, sync: true)
        mailbox.save!

        imap.login
        mailbox.imap_create

        mailbox
      end
      let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }

      it_behaves_like "mdn reply"
    end
  end
end
