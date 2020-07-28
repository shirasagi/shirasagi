require 'spec_helper'

describe "webmail_export_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "with usual mails" do
    let(:mail1) do
      Mail.new(
        from: "from-#{unique_id}@example.jp",
        to: "to-#{unique_id}@example.jp",
        subject: "subject-#{unique_id}",
        body: "message-#{unique_id}\nmessage-#{unique_id}"
      )
    end
    let(:mail2) do
      Mail.new(
        from: "from-#{unique_id}@example.jp",
        to: "to-#{unique_id}@example.jp",
        subject: "subject-#{unique_id}",
        body: "message-#{unique_id}\nmessage-#{unique_id}"
      )
    end
    let(:mail3) do
      Mail.new(
        from: "from-#{unique_id}@example.jp",
        to: "to-#{unique_id}@example.jp",
        subject: "subject-#{unique_id}",
        body: "message-#{unique_id}\nmessage-#{unique_id}"
      )
    end

    before do
      webmail_import_mail(webmail_imap, mail1)
      webmail_import_mail(webmail_imap, mail2)
      webmail_import_mail(webmail_imap, mail3)

      webmail_reload_mailboxes(webmail_imap)

      login_webmail_imap
    end

    context "export all mails" do
      it do
        visit webmail_export_mails_path(account: 0)
        within "form#item-form" do
          choose "item_all_export_all"
          perform_enqueued_jobs do
            click_on I18n.t("ss.export")
          end
        end

        within "#addon-basic" do
          expect(page).to have_content(I18n.t("gws/memo/message.export.start_message").split("\n").first)
        end

        expect(Gws::Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        within "nav.user" do
          first(".popup-notice-container a").click

          within ".popup-notice-items .list-item.unseen" do
            click_on I18n.t("webmail.export.subject")
          end
        end

        within ".ss-notification" do
          expect(page).to have_content(I18n.t("webmail.export.notify_message").split("\n").first)
          expect(page).to have_link(href: /\.zip$/)
        end
      end
    end

    context "export selected mails" do
      it do
        visit webmail_export_mails_path(account: 0)
        within "form#item-form" do
          choose "item_all_export_select"
          click_on I18n.t("ss.links.select")
        end
        wait_for_cbox do
          expect(page).to have_content(mail1.subject)
          expect(page).to have_content(mail3.subject)
          click_on mail2.subject
        end
        within "form#item-form" do
          perform_enqueued_jobs do
            click_on I18n.t("ss.export")
          end
        end

        within "#addon-basic" do
          expect(page).to have_content(I18n.t("gws/memo/message.export.start_message").split("\n").first)
        end

        expect(Gws::Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        within "nav.user" do
          first(".popup-notice-container a").click

          within ".popup-notice-items .list-item.unseen" do
            click_on I18n.t("webmail.export.subject")
          end
        end

        within ".ss-notification" do
          expect(page).to have_content(I18n.t("webmail.export.notify_message").split("\n").first)
          expect(page).to have_link(href: /\.zip$/)
        end
      end
    end

    context "export mails are only allowed at once per user" do
      before do
        args = [{"mail_ids"=>[], "root_url"=>"http://www.example.jp/", "account"=>"0"}]
        Job::Task.create!(
          user_id: webmail_imap.id, name: SecureRandom.uuid, class_name: "Webmail::MailExportJob", app_type: "sys",
          pool: "default", args: args, active_job: {
            "job_class" => "Webmail::MailExportJob", "job_id" => SecureRandom.uuid, "provider_job_id" => nil,
            "queue_name" => "default", "priority" => nil, "arguments" => args
          }
        )
      end

      it do
        visit webmail_export_mails_path(account: 0)
        within "form#item-form" do
          choose "item_all_export_all"
          click_on I18n.t("ss.export")
        end

        expect(page).to have_css("#errorExplanation", text: I18n.t("job.notice.size_limit_exceeded"))

        # export again
        within "form#item-form" do
          choose "item_all_export_all"
          click_on I18n.t("ss.export")
        end

        expect(page).to have_css("#errorExplanation", text: I18n.t("job.notice.size_limit_exceeded"))
      end
    end
  end

  context "when a subject that contains undef characters is given" do
    let(:mail) do
      Mail.new(
        from: "from-#{unique_id}@example.jp",
        to: "to-#{unique_id}@example.jp",
        subject: "Trés bien",
        body: "message-#{unique_id}\nmessage-#{unique_id}"
      )
    end

    before do
      webmail_import_mail(webmail_imap, mail)
      webmail_reload_mailboxes(webmail_imap)
      login_webmail_imap
    end

    it do
      visit webmail_export_mails_path(account: 0)
      within "form#item-form" do
        choose "item_all_export_all"
        perform_enqueued_jobs do
          click_on I18n.t("ss.export")
        end
      end

      within "#addon-basic" do
        expect(page).to have_content(I18n.t("gws/memo/message.export.start_message").split("\n").first)
      end

      expect(Gws::Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      within "nav.user" do
        first(".popup-notice-container a").click

        within ".popup-notice-items .list-item.unseen" do
          click_on I18n.t("webmail.export.subject")
        end
      end

      within ".ss-notification" do
        expect(page).to have_content(I18n.t("webmail.export.notify_message").split("\n").first)
        expect(page).to have_link(href: /\.zip$/)
      end
    end
  end

  context "when collapsed multipart message is given" do
    let(:mail) { ::File.read("#{Rails.root}/spec/fixtures/webmail/collapsed-multipart.eml") }

    before do
      webmail_import_mail(webmail_imap, mail)
      webmail_reload_mailboxes(webmail_imap)
      login_webmail_imap
    end

    it do
      visit webmail_export_mails_path(account: 0)
      within "form#item-form" do
        choose "item_all_export_all"
        perform_enqueued_jobs do
          click_on I18n.t("ss.export")
        end
      end

      within "#addon-basic" do
        expect(page).to have_content(I18n.t("gws/memo/message.export.start_message").split("\n").first)
      end

      expect(Gws::Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      within "nav.user" do
        first(".popup-notice-container a").click

        within ".popup-notice-items .list-item.unseen" do
          click_on I18n.t("webmail.export.subject")
        end
      end

      within ".ss-notification" do
        expect(page).to have_content(I18n.t("webmail.export.notify_message").split("\n").first)
        expect(page).to have_link(href: /\.zip$/)
      end
    end
  end

  context "when too long subject is given" do
    let(:mail1) do
      Mail.new(
        from: "from-#{unique_id}@example.jp",
        to: "to-#{unique_id}@example.jp",
        subject: "あいうえお" * 100,
        body: "message-#{unique_id}\nmessage-#{unique_id}"
      )
    end

    before do
      webmail_import_mail(webmail_imap, mail1)
      webmail_reload_mailboxes(webmail_imap)
      login_webmail_imap
    end

    it do
      visit webmail_export_mails_path(account: 0)
      within "form#item-form" do
        choose "item_all_export_all"
        perform_enqueued_jobs do
          click_on I18n.t("ss.export")
        end
      end

      within "#addon-basic" do
        expect(page).to have_content(I18n.t("gws/memo/message.export.start_message").split("\n").first)
      end

      expect(Gws::Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      within "nav.user" do
        first(".popup-notice-container a").click

        within ".popup-notice-items .list-item.unseen" do
          click_on I18n.t("webmail.export.subject")
        end
      end

      within ".ss-notification" do
        expect(page).to have_content(I18n.t("webmail.export.notify_message").split("\n").first)
        expect(page).to have_link(href: /\.zip$/)
        first("a").click
      end

      wait_for_download
      names = []
      Zip::File.open(downloads.first) do |zip_file|
        zip_file.each do |entry|
          names << NKF.nkf("-w", entry.name)
        end
      end
      expect(names).to be_present
      expect(names).to include(include(mail1.subject.slice(0..30)))
      expect(names).not_to include(include(mail1.subject.slice(0..40)))
    end
  end
end
