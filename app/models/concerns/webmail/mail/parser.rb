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
      size: data.attr['RFC822.SIZE'],
    }

    if data.attr['RFC822']
      self.rfc822 = data.attr['RFC822']
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
      subject: mail.subject,
      content_type: mail.message_content_type,
      has_attachment: (mail.message_content_type =='multipart/mixed' ? true : nil)
    }
  end

  # @param [Mail::Field] field
  # @return [Array]
  def parse_address_field(field)
    return [] if field.blank?

    ::Mail::AddressList.new(field.value).addresses.map do |addr|
      if addr.display_name.present?
        addr.decoded
      else
        addr.address.sub(/^"/, '').sub(/"$/, '')
      end
    end
  end

  def parse_references(references)
    return [] if references.blank?
    references.is_a?(Array) ? references : [references]
  end

  def parse_body_structure
    if body_structure.multipart? #&& body_structure.media_subtype == "MIXED"
      self.attachments = Webmail::MailPart.list(all_parts).select(&:attachment?)
    else
      self.attachments = []
    end

    if info = find_first_mime_type('text/plain')
      self.text_part_no = info[0]
      self.text_part    = info[1]
    end

    if info = find_first_mime_type('text/html')
      self.html_part_no = info[0]
      self.html_part    = info[1]
    end
  end

  def all_parts
    return @_all_parts if @_all_parts
    @_all_parts = flatten_all_parts(body_structure)
  end

  def find_first_mime_type(mime)
    all_parts.each do |pos, part|
      next if "#{part.media_type}/#{part.media_subtype}" != mime.upcase
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
    self.text = Webmail::MailPart.decode resp[0].attr["BODY[#{text_part_no}]"], text_part
    self.html = Webmail::MailPart.decode resp[0].attr["BODY[#{html_part_no}]"], html_part
  end

  def sanitize_html
    html = self.html.gsub!(/<img [^>]*?>/i) do |img|
      img.sub(/ src="cid:.*?"/i) do |src|
        cid = src.sub(/.*?cid:(.*?)".*/i, '<\\1>')
        attachments.each do |file|
          if cid == file.content_id
            type = file.content_type.sub(/;.*/, '')
            src = %( data-src="data:#{type};base64,#{Base64.strict_encode64(file.read)}")
            break
          end
        end
        src
      end
    end

    ApplicationController.helpers.sanitize_with(html, attributes: %w(data-src))
  end

  private
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
