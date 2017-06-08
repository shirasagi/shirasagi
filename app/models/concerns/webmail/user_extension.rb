module Webmail::UserExtension
  extend ActiveSupport::Concern

  attr_accessor :in_imap_password

  included do
    field :imap_host, type: String
    field :imap_auth_type, type: String
    field :imap_account, type: String
    field :imap_password, type: String
    field :imap_sent_box, type: String
    field :imap_draft_box, type: String
    field :imap_trash_box, type: String

    permit_params :imap_host, :imap_auth_type, :imap_account, :in_imap_password,
                  :imap_sent_box, :imap_draft_box, :imap_trash_box

    before_validation :set_imap_password, if: ->{ in_imap_password }
  end

  def imap_default_settings
    yaml = SS.config.webmail.clients['default'] || {}
    {
      host: yaml['host'].presence,
      options: yaml['options'].presence || {},
      auth_type: yaml['auth_type'].presence,
      account: send(yaml['account'].presence),
      password: decrypted_password
    }
  end

  def imap_settings
    user_conf = {
      host: imap_host,
      auth_type: imap_auth_type,
      account: imap_account,
      password: decrypt_imap_password
    }
    conf = imap_default_settings
    user_conf.each { |k, v| conf[k] = v if v.present? }
    conf
  end

  def imap_auth_type_options
    %w(LOGIN PLAIN CRAM-MD5 DIGEST-MD5).map { |c| [c, c] }
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

  def decrypt_imap_password
    SS::Crypt.decrypt(imap_password)
  end

  private
  def set_imap_password
    self.imap_password = SS::Crypt.encrypt(in_imap_password)
  end
end
