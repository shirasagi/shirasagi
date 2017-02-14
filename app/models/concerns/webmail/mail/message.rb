module Webmail::Mail::Message
  extend ActiveSupport::Concern

  def mail_headers
    headers = {
      to: merge_address_field(to, to_text),
      cc: merge_address_field(cc, cc_text),
      bcc: merge_address_field(bcc, bcc_text),
      from: imap.user.email_address,
      in_reply_to: in_reply_to,
      references: references,
      subject: subject
    }

    headers.select { |k, v| v.present? }
  end

  def merge_address_field(array, str)
    (array + str.to_s.split(/;/)).uniq.select { |c| c.present? }.compact
  end

  def new_mail
    if sign = Webmail::Signature.default_sign(imap.user)
      self.text = "\n\n#{sign}"
      self.html = "<p></p>" + sign.to_s.gsub(/\r\n|\n/, '<br />')
    end
  end

  def new_reply(ref)
    self.reply_uid = ref.uid
    self.to = ref.from
    set_reply_header(ref)
    set_reply_body(ref)
  end

  def new_reply_all(ref)
    self.reply_uid = ref.uid
    self.to = (ref.from + ref.to).reject { |c| c.include?(imap.user.email) }
    self.cc = ref.cc
    set_reply_header(ref)
    set_reply_body(ref)
  end

  def new_forward(ref)
    self.forward_uid = ref.uid
    self.subject = "Fw: " + ref.subject.to_s.gsub(/^Fw:\s*/, '')
    set_reply_body(ref)
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
    info = reply_body_info(ref)

    self.text = "\n\n"
    self.text += "#{sign}\n\n" if sign
    self.text += info.join("\n") + "\n"
    self.text += reply_body_text(ref).to_s

    self.html = "<p></p>"
    self.html += sign.gsub(/\r\n|\n/, '<br />') + "<br /><br />" if sign
    self.html += info.join("<br />") + "<br />"
    self.html += reply_body_html(ref).to_s
    self.html = self.html.html_safe
  end

  def reply_body_info(ref)
    data = ["------ Original Message ------"]
    data << "Date: #{ref.internal_date.strftime('%a, %d %b %Y %H:%M:%S %z')}"
    data << "From: #{ref.from.join('; ')}" if ref.from.present?
    data << "To: #{ref.to.join(' ; ')}" if ref.to.present?
    data << "Cc: #{ref.cc.join(' ; ')}" if ref.cc.present?
    data << "Subject: #{ref.subject}" if ref.subject.present?
    data
  end

  def reply_body_text(ref)
    #ref.text.to_s.gsub(/^/m, "> ")
    ref.text
  end

  def reply_body_html(ref)
    ref.html
  end
end
