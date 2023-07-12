module Webmail::Mail::Message
  extend ActiveSupport::Concern

  def mail_headers
    headers = {
      to: merge_address_field(to, to_text),
      cc: merge_address_field(cc, cc_text),
      bcc: merge_address_field(bcc, bcc_text),
      from: imap.email_address,
      subject: subject
    }
    headers[:in_reply_to] = "<#{in_reply_to}>" if in_reply_to.present?
    headers[:references] = references.to_a.map { |m| "<#{m}>" } if references.present?

    #if in_request_mdn == "1"
    #  headers[:"Disposition-Notification-To"] = Webmail::Converter.extract_address(headers[:from])
    #end

    headers.select! { |_k, v| v.present? }
    headers
  end

  def merge_address_field(array, str)
    (array + str.to_s.split(";")).uniq.select { |c| c.present? }.compact
  end

  def new_mail
    if sign = Webmail::Signature.default_sign(imap)
      self.text = "\n\n#{sign}"
      self.html = "<p></p>" + Webmail.text_to_html(sign)
    end
  end

  def new_reply(ref, without_body)
    self.reply_uid = ref.uid
    self.to = ref.from
    self.to_text = self.to.join('; ')
    set_reply_header(ref)
    set_reply_body(ref) unless without_body
  end

  def new_reply_all(ref, without_body)
    self.reply_uid = ref.uid
    self.to = (ref.from + ref.to).reject { |c| c.include?(imap.address) }
    self.cc = ref.cc
    self.to_text = self.to.join('; ')
    self.cc_text = self.cc.join('; ')
    set_reply_header(ref)
    set_reply_body(ref) unless without_body
  end

  def new_forward(ref)
    self.forward_uid = ref.uid
    self.subject = "Fw: " + ref.display_subject.to_s.gsub(/^Fw:\s*/, '')
    set_forward_body(ref)
    set_ref_files(ref.attachments)
  end

  def new_edit(ref)
    self.edit_as_new_uid = ref.uid
    self.to = ref.to
    self.cc = ref.cc
    self.bcc = ref.bcc
    self.to_text = self.to.join('; ')
    self.cc_text = self.cc.join('; ')
    self.bcc_text = self.bcc.join('; ')
    self.subject = ref.display_subject
    self.format = ref.format
    self.text = ref.text
    self.html = ref.html
    set_ref_files(ref.attachments)
  end

  def set_reply_header(ref)
    self.subject = "Re: " + ref.display_subject.to_s.gsub(/^Re:\s*/, '')

    if ref.message_id.present?
      self.in_reply_to = ref.message_id
      self.references  = [ref.message_id] + ref.references
    end
  end

  def set_reply_body(ref)
    text = html = nil
    if ref.text.present?
      text = decode_jp(ref.text.to_s)
    elsif ref.html.present?
      html = ref.sanitize_html(nil, remove_image: true)
      text = Gws::Memo.html_to_text(ref.sanitize_html(nil, remove_image: true))
    end

    if ref.html.present?
      html ||= ref.sanitize_html(nil, remove_image: true)
    elsif ref.text.present?
      html = Webmail.text_to_html(text)
    end

    send_date = ref.internal_date.in_time_zone
    from = ref.display_sender.present? ? ref.display_sender.address : t("webmail.no_senders")
    sign = Webmail::Signature.default_sign(imap)

    self.format = ref.format
    if text.present?
      self.text = Webmail.reply_text(text, send_date: send_date, from: from, sign: sign)
    end
    if html.present?
      self.html = Webmail.reply_html(html, send_date: send_date, from: from, sign: sign)
    end
  end

  def reply_body_info(ref)
    I18n.l(ref.internal_date, format: :long) + ' ' + ref.from.join(', ').to_s + ':'
  end

  def set_forward_body(ref)
    text = html = nil
    if ref.text.present?
      text = decode_jp(ref.text.to_s)
    elsif ref.html.present?
      html = ref.sanitize_html(nil, remove_image: true)
      text = Gws::Memo.html_to_text(ref.sanitize_html(nil, remove_image: true))
    end

    if ref.html.present?
      html ||= ref.sanitize_html(nil, remove_image: true)
    elsif ref.text.present?
      html = Webmail.text_to_html(text)
    end

    subject = ref.display_subject.to_s
    send_date = ref.internal_date.in_time_zone
    from = ref.display_sender.present? ? ref.display_sender.address : t("webmail.no_senders")
    sign = Webmail::Signature.default_sign(imap)

    self.format = ref.format
    if text.present?
      self.text = Webmail.forward_text(text, subject: subject, send_date: send_date, from: from, sign: sign)
    end
    if html.present?
      self.html = Webmail.forward_html(html, subject: subject, send_date: send_date, from: from, sign: sign)
    end
  end
end
