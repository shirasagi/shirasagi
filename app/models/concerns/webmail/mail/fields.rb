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
    display_address(from[0] || sender)
  end

  def display_to
    to.to_a.map { |c| display_address(c) }
  end

  def display_cc
    cc.to_a.map { |c| display_address(c) }
  end

  def display_bcc
    bcc.to_a.map { |c| display_address(c) }
  end

  def display_address(address)
    return [] if address.blank?
    begin
      addr = ::Mail::Address.new(address)
      name = addr.display_name.presence || addr.address
      OpenStruct.new(name: name, email: addr.address, address: address)
    rescue
      OpenStruct.new(name: address, email: nil, address: address)
    end
  end

  def attachments?
    has_attachment.present?
  end

  def html?
    return format == 'html' if format.present?
    !html.nil?
  end
end
