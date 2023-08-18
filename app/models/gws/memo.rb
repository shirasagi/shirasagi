module Gws::Memo
  extend Gws::ModulePermission

  set_permission_name :private_gws_memo_messages, :edit

  RFC5822_ATEXT_REGEX = /\A[0-9a-zA-Z!#$%&'*+\-\/=?^_`{|}~]+\z/

  module_function

  # mailbox         =       name-addr / addr-spec
  # name-addr       =       [display-name] angle-addr
  # angle-addr      =       [CFWS] "<" addr-spec ">" [CFWS] / obs-angle-addr
  # addr-spec       =       local-part "@" domain
  def rfc2822_mailbox(site:, name: nil, email: nil, sub: nil)
    return if name.blank? && email.blank?

    address = Mail::Address.new
    address.display_name = name if name.present?

    if email.blank?
      # RFC2822 によるとメールアドレス部 addr-spec は省略することができないので、仮初めのメールアドレスを生成する
      #
      # - シラサギのユーザーはメールアドレスを省略することができる。このようなユーザーに対して仮初めのメールアドレスが適用される。
      # - メッセージでは、共有アドレスグループや個人アドレスグループを指定することができる。
      #   このようなグループに対して仮初めのメールアドレスが適用される。
      # - メッセージにはメーリングリスト機能がある。メーリングリストを用いたメッセージに対しても仮初めのメールアドレスが適用される。
      if RFC5822_ATEXT_REGEX.match?(name)
        local_part = name
      else
        local_part = Base64.strict_encode64(name)
      end
      domain = site.canonical_domain.presence || SS.config.gws.canonical_domain.presence || "localhost.local"
      domain = "#{sub}.#{domain}" if sub.present?
      email = "#{local_part}@#{domain}"
    end

    address.address = email
    address.to_s
  end

  def reply_text(message, cur_site:, cur_user:, text: nil)
    send_date = message.send_date || message.updated
    from = message.from_member_name.presence || message.user_long_name
    sign = Gws::Memo::Signature.site(cur_site).default_sign(cur_user)

    Webmail.reply_text(text || message.text, send_date: send_date, from: from, sign: sign)
  end

  def forward_text(message, cur_site:, cur_user:, text: nil)
    send_date = message.send_date || message.updated
    from = message.from_member_name.presence || message.user_long_name
    sign = Gws::Memo::Signature.site(cur_site).default_sign(cur_user)

    Webmail.forward_text(text || message.text, subject: message.subject, send_date: send_date, from: from, sign: sign)
  end

  def reply_html(message, cur_site:, cur_user:, html: nil)
    send_date = message.send_date || message.updated
    from = message.from_member_name.presence || message.user_long_name
    sign = Gws::Memo::Signature.site(cur_site).default_sign(cur_user)

    Webmail.reply_html(html || message.html, send_date: send_date, from: from, sign: sign)
  end

  def forward_html(message, cur_site:, cur_user:, html: nil)
    send_date = message.send_date || message.updated
    from = message.from_member_name.presence || message.user_long_name
    sign = Gws::Memo::Signature.site(cur_site).default_sign(cur_user)

    Webmail.forward_html(html || message.html, subject: message.subject, send_date: send_date, from: from, sign: sign)
  end

  def text_to_html(text)
    Webmail.text_to_html(text)
  end

  def html_to_text(html)
    Webmail.html_to_text(html)
  end
end
