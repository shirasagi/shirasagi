require 'spec_helper'

describe Webmail::HistoryArchiveJob, dbscope: :example, imap: true do
  let!(:user) { webmail_imap }
  let(:mail_count) { 51 }
  let(:mail) do
    Mail.new(
      from: "from-#{unique_id}@example.jp",
      to: "to-#{unique_id}@example.jp",
      subject: "subject-#{unique_id}",
      body: "message-#{unique_id}\nmessage-#{unique_id}"
    )
  end

  describe ".perform" do
    before do
      mail_count.times do
        webmail_import_mail(user, mail)
      end
      webmail_reload_mailboxes(user)
    end

    it do
      job_class = Webmail::MailExportJob.bind(user_id: user, user_password: SS::Crypto.encrypt("pass"))
      job_class.perform_now(mail_ids: [], root_url: "#{%w(http https).sample}://#{unique_domain}/", account: "0")

      expect(Gws::Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(SS::Notification.all.count).to eq 1
      notice = SS::Notification.first
      expect(notice.group_id).to be_blank
      expect(notice.member_ids).to eq [ user.id ]
      expect(notice.user_id).to eq user.id
      expect(notice.subject).to eq I18n.t("webmail.export.subject")
      expect(notice.text).to include(I18n.t("webmail.export.notify_message", link: ""))
      expect(notice.html).to be_blank
      expect(notice.format).to eq "text"
      expect(notice.user_settings).to be_blank
      expect(notice.state).to eq "public"
      expect(notice.send_date).to be_present
      expect(notice.url).to be_blank
      expect(notice.reply_module).to be_blank
      expect(notice.reply_model).to be_blank
      expect(notice.reply_item_id).to be_blank

      download = SS::DownloadJobFile.find(user, "webmail-mails.zip")
      expect(::File.size(download.path)).to be > 0

      entries = []
      Zip::File.open(download.path) do |zip_file|
        zip_file.each do |entry|
          entries << NKF.nkf("-w", entry.name)
        end
      end
      expect(entries.length).to eq mail_count
    end
  end
end
