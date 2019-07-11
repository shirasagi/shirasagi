module Webmail
  class AllMailEnumerator
    include Enumerable

    def initialize(imap)
      @imap = imap
    end

    def each
      @imap.mailboxes.all.each do |mailbox|
        begin
          @cur_mailbox = mailbox
          @imap.select(mailbox.original_name)
        rescue => e
          Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
          next
        end

        @imap.mails.all.each do |m|
          yield m
        end
      end
    end

    def mailbox_locale_name(_mailbox)
      @cur_mailbox.locale_name
    end
  end

  class SelectedMailEnumerator
    include Enumerable

    def initialize(imap, mail_ids)
      @imap = imap
      @mail_ids = mail_ids
    end

    def each
      @mail_ids.each do |id|
        begin
          m = Webmail::Mail.find_by(id: id)
          yield m
        rescue Mongoid::Errors::DocumentNotFound => e
          Rails.logger.error("#{id}: メールの取得に失敗しました。キャッシュが不整合を起こしている可能性があるので、キャッシュを削除後、もう一度、エクスポートしてみてください。")
          Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        rescue => e
          Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        end
      end
    end

    def mailbox_locale_name(mailbox)
      @all_mailboxes = @imap.mailboxes.all
      found = @all_mailboxes.find { |mb| mb.original_name == mailbox }
      return if found.blank?

      found.locale_name
    end
  end

  class MailExportJob < SS::ApplicationJob
    include SS::ExportHelper

    def perform(opts = {})
      @datetime = Time.zone.now
      @mail_ids = opts[:mail_ids]

      imap_setting = user.imap_settings[opts[:account].to_i]
      imap_setting ||= Webmail::ImapSetting.new
      @imap = Webmail::Imap::Base.new_by_user(user, imap_setting)
      @imap.login
      @imap.select("INBOX")

      @root_url = opts[:root_url].to_s
      @output_zip = SS::DownloadJobFile.new(user, "webmail-mails-#{@datetime.strftime('%Y%m%d%H%M%S')}.zip")

      FileUtils.rm_rf(@output_zip.path)

      if @mail_ids.present?
        # export_webmail_mails
        enum = SelectedMailEnumerator.new(@imap, @mail_ids)
      else
        # export_webmail_all_mails
        enum = AllMailEnumerator.new(@imap)
      end

      @zip_creator = Webmail::MailExport::Zip.new(@output_zip.path)

      export_count = 0
      enum.each do |m|
        begin
          @imap.select(m.mailbox)
          mail = @imap.mails.find(m.uid, :rfc822)

          basename = sanitize_filename("#{mail.id}_#{mail.subject}")
          mailbox = enum.mailbox_locale_name(m.mailbox)
          if mailbox.present?
            mailbox = sanitize_filename(mailbox)
            mailbox = mailbox.tr(".", "/")
            basename = "#{mailbox}/#{basename}"
          end
          write_eml(basename, mail.rfc822)
          export_count += 1
        rescue => e
          Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
          next
        end
      end

      @zip_creator.close

      if export_count == 0
        create_notify_message(failed: true, failed_message: I18n.t("webmail.export_failed.empty_mails"))
        return
      end

      create_notify_message

      File.join(@root_url, @output_zip.url)
    ensure
      @zip_creator.close if @zip_creator
    end

    def create_notify_message(opts = {})
      item = SS::Notification.new
      item.cur_user = user
      item.member_ids = [user.id]
      item.format = "text"
      item.send_date = @datetime

      if opts[:failed]
        item.subject = I18n.t("webmail.export_failed.subject")
        item.text = opts[:failed_message].presence || I18n.t("webmail.export_failed.notify_message")
      else
        item.subject = I18n.t("webmail.export.subject")
        item.text = I18n.t("webmail.export.notify_message", link: ::File.join(@root_url, @output_zip.url))
      end

      item.save!
    end

    def write_eml(name, data)
      @zip_creator.create_entry("#{name}.eml") do |f|
        f.binmode
        f.write(data)
      end
    end
  end
end
