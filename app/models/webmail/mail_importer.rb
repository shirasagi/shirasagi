class Webmail::MailImporter
  include ActiveModel::Model

  attr_accessor :cur_user, :in_file, :account

  SUPPORTED_MIME_TYPES = %w(application/zip message/rfc822).freeze

  class << self
    def t(*args)
      human_attribute_name(*args)
    end

    def import_mails(user, account, *mails)
      importer = Webmail::MailImporter.new(cur_user: user, account: account)
      mails.each do |mail|
        importer.import_webmail_mail(mail)
      end
    end
  end

  def import_mails
    @datetime = Time.zone.now
    @ss_files_map = {}
    @gws_users_map = {}

    file_type = SS::MimeType.find(in_file.original_filename, nil)
    case file_type
    when "application/zip"
      import_from_zip_file
    when "message/rfc822"
      import_from_email_file
    end
  end

  def imap
    @map ||= begin
      imap_setting = @cur_user.imap_settings[@account]
      imap_setting ||= Webmail::ImapSetting.new
      imap = Webmail::Imap::Base.new_by_user(@cur_user, imap_setting)
      imap.login
      imap
    end
  end

  def import_webmail_mail(mail, msg)
    return if mail.blank?

    item = Webmail::Mail.new
    item.imap = imap
    item.import_mail(msg, date_time: mail.date)
  end

  private

  def import_from_zip_file
    Zip::File.open(in_file.path) do |entries|
      entries.each do |entry|
        next if !entry.file?
        next if ::File.basename(entry.name) =~ /^\./

        entry_type = SS::MimeType.find(entry.name, nil)
        next if entry_type != "message/rfc822"
        if !validate_size(decode_entry_name(entry), entry.size)
          next
        end

        msg = entry.get_input_stream.read rescue nil
        if msg.nil?
          errors.add :base, in_file.original_filename + I18n.t("errors.messages.invalid_file_type")
          next
        end

        mail = ::Mail.read_from_string(msg) rescue nil
        if mail.nil?
          errors.add :base, in_file.original_filename + I18n.t("errors.messages.invalid_file_type")
          next
        end

        import_webmail_mail(mail, msg)
      end
    end
  end

  def import_from_email_file
    if !validate_size(in_file.original_filename, in_file.size)
      return
    end

    msg = in_file.read rescue nil
    if msg.nil?
      errors.add :base, in_file.original_filename + I18n.t("errors.messages.invalid_file_type")
      return
    end

    mail = ::Mail.read_from_string(msg) rescue nil
    if msg.nil?
      errors.add :base, in_file.original_filename + I18n.t("errors.messages.invalid_file_type")
      return
    end

    import_webmail_mail(mail, msg)
  end

  def validate_size(filename, size)
    limit = SS.config.webmail.import_mail_size_limit
    return true if limit <= 0
    return true if size <= limit

    add_too_large_file_error(filename: filename, size: size, limit: limit)
    false
  end

  def add_too_large_file_error(params)
    params[:size] = params[:size].to_s(:human_size) if params[:size].is_a?(Numeric)
    params[:limit] = params[:limit].to_s(:human_size) if params[:limit].is_a?(Numeric)
    errmsg = I18n.t("errors.messages.too_large_file", **params)
    errors.add :base, errmsg
  end

  def unicode_names?(entry)
    (entry.gp_flags & Zip::Entry::EFS) == Zip::Entry::EFS
  end

  def decode_entry_name(entry)
    if unicode_names?(entry)
      name = entry.name
      name.force_encoding("UTF-8")
      name
    else
      entry.name.encode("utf-8", "cp932")
    end
  end
end
