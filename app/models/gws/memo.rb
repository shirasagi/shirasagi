module Gws::Memo
  extend Gws::ModulePermission

  set_permission_name :private_gws_memo_messages, :edit

  RFC5822_ATEXT_REGEX = /\A[0-9a-zA-Z!#$%&'*+\-\/=?^_`{|}~]+\z/.freeze

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

    ret = "\n\n"
    ret += "#{I18n.l(send_date, format: :long)}, #{message.from_member_name.presence || message.user_long_name}:\n"
    ret += (text || message.text).to_s.gsub(/^/m, '> ')

    sign = Gws::Memo::Signature.site(cur_site).default_sign(cur_user)
    if sign
      ret += "\n\n#{sign}"
    end

    ret
  end

  def forward_text(message, cur_site:, cur_user:, text: nil)
    send_date = message.send_date || message.updated

    ret = "\n\n"
    ret += "-------- #{I18n.t("gws/memo/message.forward_message_header")} --------\n"
    header = I18n.t("mongoid.attributes.gws/model/memo/message.subject")
    ret += "#{header}: #{message.subject}\n"
    header = I18n.t("mongoid.attributes.gws/model/memo/message.send_date")
    ret += "#{header}: #{I18n.l(send_date, format: :long)}\n"
    header = I18n.t("mongoid.attributes.gws/model/memo/message.from")
    ret += "#{header}: #{message.from_member_name.presence || message.user_long_name}\n"
    ret += "\n\n"
    ret += "#{I18n.l(send_date, format: :long)}, #{message.from_member_name.presence || message.user_long_name}:\n"
    ret += (text || message.text).to_s.gsub(/^/m, '> ')

    sign = Gws::Memo::Signature.site(cur_site).default_sign(cur_user)
    if sign
      ret += "\n\n#{sign}"
    end

    ret
  end

  FIGURE_STYLE = [
    "margin-block: 0",
    "margin-inline: 0"
  ].join("; ").freeze

  QUOTE_STYLE = [
    "margin-inline-start: 1em",
    "margin-inline-end: 1em",
    "padding-inline-start: 1em",
    "padding-inline-end: 1em",
    "border-left: 1px solid #000"
  ].join("; ").freeze

  def reply_html(message, cur_site:, cur_user:, html: nil)
    send_date = message.send_date || message.updated

    ret = <<~HTML
      <figure style="#{FIGURE_STYLE};">
        <figcaption>
          <time datetime="#{send_date.iso8601}">#{I18n.l(send_date, format: :long)}</time>
          <cite>#{message.from_member_name.presence || message.user_long_name}</cite>
          :
        </figcaption>
        <blockquote style="#{QUOTE_STYLE};">
          #{html || message.html}
        </blockquote>
      </figure>
    HTML

    sign = Gws::Memo::Signature.site(cur_site).default_sign(cur_user)
    if sign
      ret += text_to_html(sign)
    end

    ret
  end

  def forward_html(message, cur_site:, cur_user:, html: nil)
    send_date = message.send_date || message.updated

    ret = <<~HTML
      -------- #{I18n.t("gws/memo/message.forward_message_header")} --------<br>
      <table>
        <tbody>
          <tr>
            <th scope="row">#{I18n.t("mongoid.attributes.gws/model/memo/message.subject")}</th>
            <td>#{message.subject}</td>
          </tr>
          <tr>
            <th scope="row">#{I18n.t("mongoid.attributes.gws/model/memo/message.send_date")}</th>
            <td><time datetime="#{send_date.iso8601}">#{I18n.l(send_date, format: :long)}</time></td>
          </tr>
          <tr>
            <th scope="row">#{I18n.t("mongoid.attributes.gws/model/memo/message.from")}</th>
            <td>#{message.from_member_name.presence || message.user_long_name}</td>
          </tr>
        </tbody>
      </table>
      <br>
      #{html || message.html}
    HTML

    sign = Gws::Memo::Signature.site(cur_site).default_sign(cur_user)
    if sign
      ret += text_to_html(sign)
    end

    ret
  end

  # rubocop:disable Style::RedundantAssignment
  def text_to_html(text)
    return text if text.blank?

    text = ApplicationController.helpers.sanitize(text)
    text = ERB::Util.h(text)
    text = text.split(/\R\R+/).map { |t| "<p>#{t}</p>" }.join
    text = text.gsub(/\R/, '<br />')
    text
  end
  # rubocop:enable Style::RedundantAssignment

  def html_to_text(html)
    return html if html.blank?

    fragment = Nokogiri::HTML.fragment(html.gsub(/<br.*?>/, "\n").gsub(/<hr.*?>/, "\n"))
    fragment.text
  end
end
