module Webmail::Mail::Parser
  extend ActiveSupport::Concern

  def parse_message(msg)
    envelope = msg.attr["ENVELOPE"]
    mail = ::Mail.read_from_string msg.attr['RFC822']

    self.attributes = {
      uid: msg.attr["UID"],
      message_id: envelope.message_id,
      size: msg.attr['RFC822.SIZE'],
      flags: msg.attr['FLAGS'].map(&:to_s).presence,
      date: envelope.date,
      from: self.class.build_addresses(envelope.from)[0],
      sender: self.class.build_addresses(envelope.sender)[0],
      to: self.class.build_addresses(envelope.to).presence,
      cc: self.class.build_addresses(envelope.cc).presence,
      bcc: self.class.build_addresses(envelope.bcc).presence,
      reply_to: self.class.build_addresses(envelope.reply_to).presence,
      in_reply_to: self.class.build_addresses(envelope.in_reply_to).presence,
      subject: envelope.subject.try(:toutf8),
      attachments_count: mail.attachments.size
    }
  end

  def parse_body(msg)
    self.rfc822 = msg.attr['RFC822']
    mail = ::Mail.read_from_string(rfc822)

    self.text = mail.text_part.decoded.toutf8 if mail.text_part
    self.html = mail.html_part.decoded.toutf8 if mail.html_part

    if mail.body.present?
      if mail.content_type.start_with?('text/html')
        self.html ||= mail.body.decoded.toutf8
      else
        self.text ||= mail.body.decoded.toutf8
      end
    end
    self.attachments = mail.attachments
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

  def mail_attributes=(attr)
    self.attributes = attr

    self.to = join_address_field(to, to_text)
    self.cc = join_address_field(cc, cc_text)
    self.bcc = join_address_field(bcc, bcc_text)
  end

  def join_address_field(addr, str)
    (addr + str.to_s.split(/;/)).uniq.select { |c| c.present? }
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
