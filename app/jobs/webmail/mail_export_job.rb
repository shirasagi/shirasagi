class Webmail::MailExportJob < SS::ApplicationJob
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
      export_webmail_mails
    else
      export_webmail_all_mails
    end

    zip = Webmail::MailExport::Zip.new(@output_zip.path)
    zip.output_dir = @output_dir
    zip.compress

    FileUtils.rm_rf(@output_dir)

    File.join(@root_url, @output_zip.url)
  end

  def export_webmail_mails
    @mail_ids.each do |id|
      m = Webmail::Mail.find_by(id: id)
      @imap.select(m.mailbox)
      mail = @imap.mails.find m.uid, :rfc822
      write_eml(sanitize_filename("#{mail.id}_#{mail.subject}"), mail.rfc822)
    end
  end

  def export_webmail_all_mails
    @imap.mailboxes.all.each do |mailbox|
      @imap.select(mailbox.original_name)
      @imap.mails.all.each do |m|
        mail = @imap.mails.find m.uid, :rfc822
        write_eml(sanitize_filename("#{mail.id}_#{mail.subject}"), mail.rfc822)
      end
    end
  end

  def create_notify_message
    item = Webmail::Notice.new
    item.cur_site = site
    item.cur_user = user
    item.member_ids = [user.id]
    item.subject = I18n.t("webmail.export.subject")
    item.format = "text"
    item.text = I18n.t("webmail.export.notiry_message", link: ::File.join(@root_url, @output_zip.url))
    item.send_date = @datetime
    item.save!
  end

  def write_eml(name, data)
    File.binwrite("#{@output_dir}/#{name}.eml", data)
  end

  def sanitize_filename(filename)
    filename.gsub(/[\<\>\:\"\/\\\|\?\*]/, '_').slice(0...250)
  end
end
