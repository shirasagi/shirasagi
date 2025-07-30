# Webmail::MailPart または Webmail::StoredMailPart をラップし、SS::File 類似インターフェースを提供する
# ファイルに関する共通処理をメールの手ぷファイルでも使用できるようにする。
class Webmail::PartFile
  include ActiveModel::Model

  attr_accessor :webmail_mode, :account, :mail, :part

  delegate :filename, :content_type, :image?, :size, to: :part

  def id
    "ref-#{part.section}"
  end

  def name
    ::File.basename(part.filename)
  end

  def extname
    return "" if part.filename.blank?

    ret = ::File.extname(part.filename)
    return "" if ret.blank?

    ret = ret[1..-1] if ret.start_with?(".")
    ret
  end

  def url
    # /.webmail/:webmail_mode-:account/mails/:mailbox/:id/parts/:section
    Rails.application.routes.url_helpers.parts_webmail_mail_path(
      webmail_mode: webmail_mode,
      account: account,
      mailbox: mail.mailbox,
      id: mail.uid,
      section: part.section
    )
  end

  def no_cache_url
    # /.webmail/:webmail_mode-:account/mails/:mailbox/:id/parts/:section?_=1734810
    Rails.application.routes.url_helpers.parts_webmail_mail_path(
      webmail_mode: webmail_mode,
      account: account,
      mailbox: mail.mailbox,
      id: mail.uid,
      section: part.section,
      _: Time.zone.now.to_i
    )
  end

  alias thumb_url url
  alias thumb_no_cache_url no_cache_url

  def humanized_name
    "#{::File.basename(part.filename, ".*")} (#{extname.upcase} #{size.to_fs(:human_size)})"
  end

  def read
    effective_part = part
    if !effective_part.is_a?(Webmail::StoredMailPart) && effective_part.data.blank?
      effective_part = mail.imap.mails.find_part(mail.uid, part.section)
    end

    effective_part.decoded
  end

  def updated
    mail.date.try(:in_time_zone) || mail.updated.try(:in_time_zone) || Time.zone.now
  end

  def becomes_with_model
    self
  end

  # def save_to_file(attrs = {})
  #   attrs = attrs.dup
  #   attrs[:name] ||= name
  #   attrs[:filename] ||= filename
  #   attrs[:content_type] ||= content_type
  #   attrs[:model] ||= "ss/temp_file"
  #
  #   SS::File.create_empty!(attrs) do |file|
  #     ::File.open(file.path, "wb") do |f|
  #       f.write part.decoded
  #     end
  #   end
  # end
end
