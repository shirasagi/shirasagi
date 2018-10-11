class Webmail::MailImporter
  include ActiveModel::Model
  include Sys::SiteImport::File

  attr_accessor :cur_user, :in_file, :account

  def import_mails
    @datetime = Time.zone.now
    @import_dir = "#{Rails.root}/private/import/webmail-mails-#{@datetime.strftime('%Y%m%d%H%M%S')}"
    @ss_files_map = {}
    @gws_users_map = {}

    FileUtils.rm_rf(@import_dir)
    FileUtils.mkdir_p(@import_dir)

    Zip::File.open(in_file.path) do |entries|
      entries.each do |entry|
        path = "#{@import_dir}/" + entry.name.encode("utf-8", "cp932").tr('\\', '/')

        if entry.directory?
          FileUtils.mkdir_p(path)
        else
          File.binwrite(path, entry.get_input_stream.read)
        end
      end
    end

    names = Dir.glob("#{@import_dir}/*.eml").each.map { |path| File.basename(path).sub(".eml", "") }
    names.each do |name|
      import_webmail_mail(name)
    end

    FileUtils.rm_rf(@import_dir)
  end

  def import_webmail_mail(name)
    msg = read_eml(name)

    item = Webmail::Mail.new
    imap_setting = @cur_user.imap_settings[@account]
    imap_setting = Webmail::ImapSetting.new unless imap_setting
    imap = Webmail::Imap::Base.new(@cur_user, imap_setting)
    imap.login
    imap.select("INBOX")
    item.imap = imap
    item.import_mail(msg.to_s)
  end

  def read_eml(name)
    path = "#{@import_dir}/#{name}.eml"
    return [] unless File.file?(path)
    Mail.read(path)
  end

  class << self
    def t(*args)
      human_attribute_name(*args)
    end
  end
end
