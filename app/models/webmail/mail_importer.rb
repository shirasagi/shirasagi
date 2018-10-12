class Webmail::MailImporter
  include ActiveModel::Model

  attr_accessor :cur_user, :in_file, :account

  SUPPORTED_MIME_TYPES = %w(application/zip message/rfc822).freeze
  MAX_MAIL_SIZE = 10 * 1_024 * 1_024

  class << self
    def t(*args)
      human_attribute_name(*args)
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

  private

  def import_from_zip_file
    Zip::File.open(in_file.path) do |entries|
      entries.each do |entry|
        next if !entry.file?

        entry_type = SS::MimeType.find(entry.name, nil)
        next if entry_type != "message/rfc822"
        if entry.size > MAX_MAIL_SIZE
          add_too_large_file_error(filename: entry.name.encode("utf-8", "cp932"), size: entry.size, limit: MAX_MAIL_SIZE)
          next
        end

        msg = ::Mail.read_from_string(entry.get_input_stream.read) rescue nil
        if msg.nil?
          errors.add :base, in_file.original_filename + I18n.t("errors.messages.invalid_file_type")
          next
        end

        import_webmail_mail(msg)
      end
    end
  end

  def import_from_email_file
    if in_file.size > MAX_MAIL_SIZE
      add_too_large_file_error(filename: in_file.original_filename, size: in_file.size, limit: MAX_MAIL_SIZE)
      return
    end

    msg = ::Mail.read_from_string(in_file.read) rescue nil
    if msg.nil?
      errors.add :base, in_file.original_filename + I18n.t("errors.messages.invalid_file_type")
      return
    end

    import_webmail_mail(msg)
  end

  def import_webmail_mail(msg)
    item = Webmail::Mail.new
    imap_setting = @cur_user.imap_settings[@account]
    imap_setting = Webmail::ImapSetting.new unless imap_setting
    imap = Webmail::Imap::Base.new(@cur_user, imap_setting)
    imap.login
    imap.select("INBOX")
    item.imap = imap
    item.import_mail(msg.to_s)
  end

  def add_too_large_file_error(params)
    params[:size] = params[:size].to_s(:human_size) if params[:size].is_a?(Numeric)
    params[:limit] ||= MAX_MAIL_SIZE
    params[:limit] = params[:limit].to_s(:human_size) if params[:limit].is_a?(Numeric)
    errmsg = I18n.t("errors.messages.too_large_file", params)
    errors.add :base, errmsg
  end
end
