module Gws::Memo
  extend Gws::ModulePermission

  set_permission_name :private_gws_memo_messages, :edit

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
      # - メッセージでは、共有アドレスグループや個人アドレスグループを指定することができる。このようなグループに対して仮初めのメールアドレスが適用される。
      # - メッセージにはメーリングリスト機能がある。メーリングリストを用いたメッセージに対しても仮初めのメールアドレスが適用される。
      local_part = Base64.strict_encode64(name).gsub(/=+$/, "")
      domain = site.canonical_domain.presence || SS.config.gws.canonical_domain.presence || "localhost.local"
      domain = "#{sub}.#{domain}" if sub.present?
      email = "#{local_part}@#{domain}"
    end

    address.address = email
    address.to_s
  end
end
