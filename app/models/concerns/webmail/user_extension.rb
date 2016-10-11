module Webmail::UserExtension
  extend ActiveSupport::Concern

  attr_accessor :in_imap_password

  included do
    field :imap_host, type: String
    field :imap_account, type: String
    field :imap_password, type: String

    permit_params :imap_host, :imap_account, :in_imap_password

    before_validation :set_imap_password, if: ->{ in_imap_password.present? }
  end

  def imap_settings
    conf = {
      host: imap_host,
      account: imap_account,
      password: imap_password
    }
    return nil if conf[:host].blank? || conf[:account].blank? || conf[:password].blank?
    conf
  end

  private
    def set_imap_password
      self.imap_password = in_imap_password
    end
end
