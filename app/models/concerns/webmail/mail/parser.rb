module Webmail::Mail::Parser
  extend ActiveSupport::Concern

  attr_accessor :header, :rfc822, :body_structure,
                :text_part_no, :text_part,
                :html_part_no, :html_part

  def parse(data)
    self.attributes = {
      uid: data.attr["UID"],
      internal_date: data.attr['INTERNALDATE'],
      flags: data.attr['FLAGS'] || [],
      size: data.attr['RFC822.SIZE']
    }
    self.flags = flags.map(&:to_sym)

    if data.attr['RFC822']
      self.rfc822 = data.attr['RFC822']
      parse_rfc822_body
    end

    if data.attr['RFC822.HEADER']
      self.header = data.attr['RFC822.HEADER']
      parse_header
    end

    if data.attr['BODYSTRUCTURE']
      self.body_structure = data.attr['BODYSTRUCTURE']
      parse_body_structure
    end
  end

  def parse_header
    mail = ::Mail.read_from_string(header)

    self.attributes = {
      message_id: mail.message_id,
      sender: mail.sender,
      from: parse_address_field(mail[:from]),
      to: parse_address_field(mail[:to]),
      cc: parse_address_field(mail[:cc]),
      bcc: parse_address_field(mail[:bcc]),
      reply_to: parse_address_field(mail[:reply_to]),
      in_reply_to: mail.in_reply_to,
      references: parse_references(mail.references),
      subject: parse_subject(mail),
      content_type: mail.mime_type,
      has_attachment: (mail.mime_type =='multipart/mixed' ? true : nil),
      disposition_notification_to: parse_address_field(mail[:disposition_notification_to])
    }
  end

  # @param [Mail::Field] field
  # @return [Array]
  def parse_address_field(field)
    return [] if field.blank?

    if field.value.include?('=?ISO-2022-JP?')
      value = NKF.nkf("-w", field.value)
    else
      value = field.value
    end

    ::Mail::AddressList.new(value).addresses.map do |addr|
      if addr.display_name.present?
        #charset = field.value.start_with?('=?ISO-2022-JP?') ? 'CP50220' : nil
        addr.decoded.encode('UTF-8', nil) rescue addr.decoded
      else
        addr.address
      end
    end
  rescue Mail::Field::ParseError, StandardError
    [field.decoded] rescue [field.value]
  end

  def parse_references(references)
    return [] if references.blank?
    references.is_a?(Array) ? references : [references]
  end

  def parse_subject(mail)
    value = mail.header_fields.find { |m| m.name.casecmp('subject') == 0 }.try(:value)
    return mail.subject unless value

    if value.include?('=?ISO-2022-JP?')
      NKF.nkf("-w", value)
    else
      decode_jp(mail.subject, nil)
    end
  end

  def parse_body_structure
    text_part, html_part, other_parts = split_body_and_others
    if text_part.present?
      self.format       = 'text'
      self.text_part_no = text_part[0]
      self.text_part    = text_part[1]
    end

    if html_part.present?
      self.format       = 'html'
      self.html_part_no = html_part[0]
      self.html_part    = html_part[1]
    end

    self.attachments = []
    if other_parts.present?
      other_parts.each do |sec, part|
        self.attachments << Webmail::MailPart.new(part, sec)
      end
    end
  end

  def split_body_and_others
    text_part = find_first_mime_type('text/plain')
    html_part = find_first_mime_type('text/html')

    other_parts = all_parts.dup
    other_parts.reject! { |pos, _part| pos == text_part[0] } if text_part.present?
    other_parts.reject! { |pos, _part| pos == html_part[0] } if html_part.present?

    [ text_part, html_part, other_parts ]
  end

  def all_parts
    return @_all_parts if @_all_parts
    @_all_parts = flatten_all_parts(body_structure)
  end

  def find_first_mime_type(mime)
    all_parts.each do |pos, part|
      next if "#{part.media_type}/#{part.subtype}" != mime.upcase
      next if part.disposition && part.disposition.dsp_type == 'ATTACHMENT'
      return [pos, part]
    end
    return nil
  end

  def fetch_body
    attr = []
    attr << "BODY[#{text_part_no}]" if text_part_no
    attr << "BODY[#{html_part_no}]" if html_part_no
    return if attr.blank?

    resp = imap.conn.uid_fetch(uid, attr)
    self.text = Webmail::MailPart.decode(resp[0].attr["BODY[#{text_part_no}]"], text_part, charset: true)
    self.html = Webmail::MailPart.decode(resp[0].attr["BODY[#{html_part_no}]"], html_part, charset: true, html_safe: true)
  end

  def parse_rfc822_body
    read_rfc822 if rfc822.blank?
    return if rfc822.blank?

    msg = Mail::Message.new(rfc822)
    if msg.multipart?
      if text_part = msg.find_first_mime_type('text/plain')
        self.format = 'text'
        self.text = decode_jp(text_part.body.to_s, text_part.charset)
      end
      if html_part = msg.find_first_mime_type('text/html')
        self.format = 'html'
        self.html = decode_jp(html_part.body.to_s, html_part.charset)
      end

      @_all_parts = {}
      self.attachments = []
      msg.all_parts.each_with_index do |part, i|
        @_all_parts[i + 1] = part
        next if part == text_part || part == html_part
        self.attachments << Webmail::StoredMailPart.new(part, i + 1)
      end
    else
      if msg.mime_type == 'text/plain'
        self.format = 'text'
        self.text = decode_jp(msg.body.to_s, msg.charset)
      end
      if msg.mime_type == 'text/html'
        self.format = 'html'
        self.html = decode_jp(msg.body.to_s, msg.charset)
      end
    end
  end

  private

  def decode_jp(str, src_encoding = nil)
    str.force_encoding('UTF-8')
    return str if str.blank? || src_encoding == 'UTF-8'
    src_encoding = 'CP50220' if src_encoding.try(:upcase) == 'ISO-2022-JP'
    str.encode('UTF-8', src_encoding) rescue str.encode('UTF-8')
  end

  def flatten_all_parts(part, pos = [], buf = {})
    if part.multipart?
      part.parts.each_with_index do |p, idx|
        buf = flatten_all_parts(p, pos + [idx + 1], buf)
      end
    else
      pos = [1] if pos.blank?
      buf[pos.join('.')] = part
    end
    buf
  end
end
