module Webmail::UserExtension
  extend ActiveSupport::Concern

  attr_accessor :in_imap_password

  included do
    field :imap_host, type: String
    field :imap_account, type: String
    field :imap_password, type: String
    field :imap_sent_box, type: String
    field :imap_draft_box, type: String
    field :imap_trash_box, type: String

    permit_params :imap_host, :imap_account, :in_imap_password
    permit_params :imap_sent_box, :imap_draft_box, :imap_trash_box

    before_validation :set_imap_password, if: ->{ in_imap_password.present? }
  end

  def imap_settings
    conf = {
      host: imap_host,
      account: imap_account,
      password: imap_decrypted_password
    }
    return nil if conf[:host].blank? || conf[:account].blank? || conf[:password].blank?
    conf
  end

  def imap_special_mailboxes
    [imap_sent_box, imap_draft_box, imap_trash_box]
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

  def imap_decrypted_password
    SS::Crypt.decrypt(imap_password)
  end

  private
    def set_imap_password
      self.imap_password = SS::Crypt.encrypt(in_imap_password)
    end
end
