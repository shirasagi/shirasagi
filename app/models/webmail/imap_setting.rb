class Webmail::ImapSetting < Hash
  include ActiveModel::Model

  validates :name, presence: true
  validates :imap_port, numericality: { only_integer: true, greater_than: 0, allow_blank: true }
  validates :threshold_mb, numericality: { only_integer: true, greater_than: 0, allow_blank: true }
  validates :imap_auth_type, inclusion: { in: %w(LOGIN PLAIN CRAM-MD5 DIGEST-MD5), allow_blank: true }
  validates :imap_account, presence: true, on: :group
  validates :imap_password, presence: true, on: :group

  class << self
    def default
      ret = new
      ret[:name] = I18n.t('webmail.default_settings')
      ret
    end
  end

  def name
    self[:name]
  end

  def from
    self[:from]
  end

  def address
    self[:address]
  end

  def imap_host
    self[:imap_host]
  end

  def imap_port
    self[:imap_port].numeric? ? self[:imap_port].to_i : nil
  end

  def imap_ssl_use
    self[:imap_ssl_use]
  end

  def imap_auth_type
    self[:imap_auth_type]
  end

  def imap_account
    self[:imap_account]
  end

  def in_imap_password
    self[:in_imap_password]
  end

  def imap_password
    self[:imap_password]
  end

  def decrypt_imap_password
    SS::Crypto.decrypt(imap_password.to_s)
  end

  def imap_sent_box
    self[:imap_sent_box].presence || "INBOX.Sent"
  end

  def imap_draft_box
    self[:imap_draft_box].presence || "INBOX.Draft"
  end

  def imap_trash_box
    self[:imap_trash_box].presence || "INBOX.Trash"
  end

  def imap_alias
    self[:imap_alias]
  end

  def threshold_mb
    self[:threshold_mb]
  end

  def set_imap_password
    return if self[:in_imap_password].blank?
    self[:imap_password] = SS::Crypto.encrypt(self[:in_imap_password])
    self.delete(:in_imap_password)
  end

  def imap_settings(default_conf = {})
    use_ssl = imap_ssl_use == "enabled"
    conf = default_conf.dup
    conf[:from] = from if from.present?
    conf[:address] = address if address.present?
    conf[:host] = imap_host if imap_host.present?
    conf[:options] ||= {}
    conf[:options][:port] = imap_port if imap_port
    if use_ssl
      conf[:options][:ssl] = { verify_mode: OpenSSL::SSL::VERIFY_PEER }
    end
    conf[:auth_type] = imap_auth_type if imap_auth_type.present?
    conf[:account] = imap_account if imap_account.present?
    conf[:password] = decrypt_imap_password if decrypt_imap_password.present?
    conf[:threshold_mb] = threshold_mb if threshold_mb.present?
    conf[:imap_sent_box] = imap_sent_box if imap_sent_box.present?
    conf[:imap_draft_box] = imap_draft_box if imap_draft_box.present?
    conf[:imap_trash_box] = imap_trash_box if imap_trash_box.present?
    conf[:imap_alias] = imap_alias if imap_alias.present?
    conf
  end

  def t(name, opts = {})
    self.class.t name, opts
  end

  def tt(key, html_wrap = true)
    self.class.tt key, html_wrap
  end

  class << self
    def t(*args)
      human_attribute_name *args
    end
  end
end
