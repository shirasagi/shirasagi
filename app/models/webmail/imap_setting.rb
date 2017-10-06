class Webmail::ImapSetting < Hash
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

  def valid?
    imap_host.present? && imap_account.present?
  end

  def set_imap_password
    return if self[:in_imap_password].blank?
    self[:imap_password] = SS::Crypt.encrypt(self[:in_imap_password])
    self.delete(:in_imap_password)
  end

  def imap_settings(default_conf = {})
    user_conf = {
      host: imap_host,
      auth_type: imap_auth_type,
      account: imap_account,
      password: decrypt_imap_password
    }
    user_conf.each { |k, v| default_conf[k] = v if v.present? }
    default_conf
  end
end
