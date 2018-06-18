class Webmail::ImapSetting < Hash
  include ActiveModel::Model

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
    SS::Crypt.decrypt(imap_password.to_s)
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

  def threshold_mb
    self[:threshold_mb]
  end

  def valid?
    errors.add :name, :blank if name.blank?
    errors.empty?
  end

  def set_imap_password
    return if self[:in_imap_password].blank?
    self[:imap_password] = SS::Crypt.encrypt(self[:in_imap_password])
    self.delete(:in_imap_password)
  end

  def imap_settings(default_conf = {})
    user_conf = {
      from: from,
      address: address,
      host: imap_host,
      auth_type: imap_auth_type,
      account: imap_account,
      password: decrypt_imap_password,
      threshold_mb: threshold_mb,
      imap_sent_box: imap_sent_box,
      imap_draft_box: imap_draft_box,
      imap_trash_box: imap_trash_box
    }
    user_conf.each { |k, v| default_conf[k] = v if v.present? }
    default_conf
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
