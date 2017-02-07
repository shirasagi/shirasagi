module Webmail::Mail::MessageBuilder
  extend ActiveSupport::Concern

  def mail_attributes=(attr)
    self.attributes = attr

    self.to = join_address_field(to, to_text)
    self.cc = join_address_field(cc, cc_text)
    self.bcc = join_address_field(bcc, bcc_text)
  end

  def join_address_field(addr, str)
    (addr + str.to_s.split(/;/)).uniq.select { |c| c.present? }
  end

  def mail_attributes
    params = {
      from: imap.user.email_address,
      to: to,
      cc: cc,
      bcc: bcc,
      subject: subject,
    }

    if reply_uid.present?
      ref = self.class.imap_find(reply_uid)
      params[:in_reply_to] = ref.message_id
      params[:references] = ([ref.message_id] + ref.references).join("\n ")
    end

    params
  end

  def new_create
    sign = Webmail::Signature.default_sign(imap.user)
    self.text = "\n\n#{sign}"
  end

  def new_reply(uid)
    self.reply_uid = uid
    ref = self.class.imap_find(reply_uid)

    self.to = [ref.from] if ref.from.present?
    self.subject = "Re: " + ref.subject.to_s.gsub(/^Re:\s*/, '')
    new_reply_body(ref)
  end

  def new_reply_all(uid)
    self.reply_uid = uid
    ref = self.class.imap_find(reply_uid)

    self.to = ([ref.from] + ref.to).reject { |c| c.include?(imap.user.email) } if ref.from.present?
    self.cc = ref.cc if ref.cc.present?
    self.subject = "Re: " + ref.subject.to_s.gsub(/^Re:\s*/, '')
    new_reply_body(ref)
  end

  def new_forward(uid)
    self.forward_uid = uid
    ref = self.class.imap_find(forward_uid)

    self.subject = "Fw: " + ref.subject.to_s.gsub(/^Fw:\s*/, '')
    new_reply_body(ref)
  end

  def new_reply_body(ref)
    sign = Webmail::Signature.default_sign(imap.user)
    self.format = ref.format
    self.text = [sign, ref.reply_text].compact.join("\n\n")
    self.html = [sign, ref.reply_html].compact.join("<br />\n<br />\n")
  end

  def reply_header
    data = ["------ Original Message ------"]
    data << "Date: #{internal_date.strftime('%a, %d %b %Y %H:%M:%S %z')}" if internal_date.present?
    data << "From: #{from}" if from.present?
    data << "To: #{to.join(' ; ')}" if to.present?
    data << "Cc: #{cc.join(' ; ')}" if cc.present?
    data << "Subject: #{subject}" if subject.present?
    data
  end

  def reply_text
    #text = text.to_s.gsub(/^/m, "> ")
    reply_header.join("\n").to_s + "\n\n#{text}"
  end

  def reply_html
    reply_header.join("<br />\n").to_s + "\n\n#{html}"
  end
end
