module Webmail
  class AllMailEnumerator
    include Enumerable

    def initialize(imap)
      @imap = imap
    end

    def each
      @imap.mailboxes.all.each do |mailbox|
        begin
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
  end

  class SelectedMailEnumerator
    include Enumerable

    def initialize(imap, mail_ids)
      @imap = imap
      @mail_ids = mail_ids
    end

    def each
      @mail_ids.each do |id|
        m = Webmail::Mail.find_by(id: id)
        yield m
      end
    end
  end

  class MailExportJob < SS::ApplicationJob
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
      @output_dir = @output_zip.path.sub(::File.extname(@output_zip.path), "")

      FileUtils.rm_rf(@output_dir)
      FileUtils.rm_rf(@output_zip.path)
      FileUtils.mkdir_p(@output_dir)

      if @mail_ids.present?
        # export_webmail_mails
        enum = SelectedMailEnumerator.new(@imap, @mail_ids)
      else
        # export_webmail_all_mails
        enum = AllMailEnumerator.new(@imap)
      end

      export_count = 0
      enum.each do |m|
        begin
          @imap.select(m.mailbox)
          mail = @imap.mails.find m.uid, :rfc822
          write_eml(sanitize_filename("#{mail.id}_#{mail.subject}"), mail.rfc822)
          export_count += 1
        rescue => e
          Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
          next
        end
      end

      if export_count == 0
        FileUtils.rm_rf(@output_dir)
        create_notify_message(failed: true, failed_message: I18n.t("webmail.export_failed.empty_mails"))
        return
      end

      zip = Webmail::MailExport::Zip.new(@output_zip.path)
      zip.output_dir = @output_dir
      zip.compress

      FileUtils.rm_rf(@output_dir)

      create_notify_message

      File.join(@root_url, @output_zip.url)
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
      File.binwrite("#{@output_dir}/#{name}.eml", data)
    end

    def sanitize_filename(filename)
      filename.gsub(/[\<\>\:\"\/\\\|\?\*]/, '_').slice(0..60)
    end
  end
end
