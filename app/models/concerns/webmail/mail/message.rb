module Webmail::Mail::Message
  extend ActiveSupport::Concern

  def mail_headers
    headers = {
      to: merge_address_field(to, to_text),
      cc: merge_address_field(cc, cc_text),
      bcc: merge_address_field(bcc, bcc_text),
      from: imap.user.email_address,
      subject: subject
    }
    headers[:in_reply_to] = "<#{in_reply_to}>" if in_reply_to.present?
    headers[:references] = references.to_a.map { |m| "<#{m}>" } if references.present?

    if in_request_mdn == "1"
      headers[:"Disposition-Notification-To"] = Webmail::Converter.extract_address(headers[:from])
    end

    headers.select { |k, v| v.present? }
  end

  def merge_address_field(array, str)
    (array + str.to_s.split(/;/)).uniq.select { |c| c.present? }.compact
  end

  def new_mail
    if sign = Webmail::Signature.default_sign(imap.user)
      self.text = "\n\n#{sign}"
      self.html = "<p></p>" + h(sign.to_s).gsub(/\r\n|\n/, '<br />')
    end
  end

  def new_reply(ref)
    self.reply_uid = ref.uid
    self.to = ref.from.map { |adr| adr.gsub("\"", "") }
    self.to_text = self.to.join('; ')
    set_reply_header(ref)
    set_reply_body(ref)
  end

  def new_reply_all(ref)
    self.reply_uid = ref.uid
    self.to = (ref.from + ref.to).reject { |c| c.include?(imap.user.email) }.map { |adr| adr.gsub("\"", "") }
    self.cc = ref.cc.map { |adr| adr.gsub("\"", "") }
    self.to_text = self.to.join('; ')
    self.cc_text = self.cc.join('; ')
    set_reply_header(ref)
    set_reply_body(ref)
  end

  def new_forward(ref)
    self.forward_uid = ref.uid
    self.subject = "Fw: " + ref.subject.to_s.gsub(/^Fw:\s*/, '')
    set_reply_body(ref)
    set_ref_files(ref.attachments)
  end

  def set_reply_header(ref)
    self.subject = "Re: " + ref.subject.to_s.gsub(/^Re:\s*/, '')

    if ref.message_id.present?
      self.in_reply_to = ref.message_id
      self.references  = [ref.message_id] + ref.references
    end
  end

  def set_reply_body(ref)
    sign = Webmail::Signature.default_sign(imap.user)
    self.format = ref.format
    self.text = reply_body_text(ref, sign)
    self.html = reply_body_html(ref, sign)
  end

  def reply_body_info(ref)
    I18n.l(ref.internal_date, format: :long) + ' ' + ref.from.join(', ').to_s + ':'
  end

  def reply_body_text(ref, sign = nil)
    text = "\n\n"
    text += "#{sign}\n\n" if sign.present?
    text += reply_body_info(ref) + "\n"
    text += ref.text.to_s.gsub(/^/m, "> ")
    text
  end

  def reply_body_html(ref, sign = nil)
    if ref.html.present?
      bq = ref.sanitize_html(remove_image: true)
    else
      bq = h(ref.text.to_s).gsub(/\r\n|\n/, '<br />')
    end

    html = "<p></p>"
    html += "<p>" + h(sign).gsub(/\r\n|\n/, '<br />') + "</p>" if sign.present?
    html += "<div>" + h(reply_body_info(ref)) + "</div>"
    html += "<blockquote style='margin: 0 0 0 1ex'>#{bq}</blockquote>"
    html
  end

  def h(str)
    ERB::Util.h(str)
  end
end
