module Webmail::Mail::Fields
  extend ActiveSupport::Concern

  def display_size
    size = (self.size < 1024) ? 1024 : self.size
    ActionController::Base.helpers.number_to_human_size(size, precision: 0)
  end

  def display_subject
    subject.presence || "No title"
  end

  def display_sender
    display_address(sender || from[0])
  end

  def display_to
    to.map { |c| display_address(c) }
  end

  def display_cc
    cc.map { |c| display_address(c) }
  end

  def display_bcc
    bcc.map { |c| display_address(c) }
  end

  def display_address(address)
    return nil if address.blank?
    addr = ::Mail::Address.new(Net::IMAP.encode_utf7(address))
    return addr.address if addr.display_name.blank?
    Net::IMAP.decode_utf7(addr.display_name)
  end

  def attachments?
    has_attachment.present?
  end

  def html?
    return format == 'html' if format.present?
    !html.nil?
  end
end
