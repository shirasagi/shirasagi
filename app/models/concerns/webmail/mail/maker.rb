module Webmail::Mail::Maker
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
    sign = Webmail::Signature.default_sign(user)
    self.text = "\n\n#{sign}"
  end

  def new_reply(uid)
    self.reply_uid = uid
    ref = self.class.imap_find(reply_uid)

    self.to = [ref.from] if ref.from.present?

    sign = Webmail::Signature.default_sign(user)
    self.subject = "Re: " + ref.subject.to_s.gsub(/^Re:\s*/, '')
    self.text = [sign, "------ Original Message ------", ref.text.to_s.gsub(/^/m, "> ")].compact.join("\n\n")
    self.html = [sign, ref.html].compact.join("<hr />") if ref.html?
  end

  def new_reply_all(uid)
    self.reply_uid = uid
    ref = self.class.imap_find(reply_uid)

    self.to = ([ref.from] + ref.to).reject { |c| c.include?(imap.user.email) } if ref.from.present?
    self.cc = ref.cc if ref.cc.present?

    sign = Webmail::Signature.default_sign(user)
    self.subject = "Re: " + ref.subject.to_s.gsub(/^Re:\s*/, '')
    self.text = [sign, "------ Original Message ------", ref.text.to_s.gsub(/^/m, "> ")].compact.join("\n\n")
    self.html = [sign, ref.html].compact.join("<hr />") if ref.html?
  end

  def new_forward(uid)
    self.forward_uid = uid
    ref = self.class.imap_find(forward_uid)

    sign = Webmail::Signature.default_sign(user)
    self.subject = "Fw: " + ref.subject.to_s
    self.text = [sign, "------ Original Message ------", ref.text].compact.join("\n\n")
    self.html = [sign, ref.html].compact.join("<hr />") if ref.html?
  end
end
