module Webmail
  extend Sys::ModulePermission

  class CP50221Encoder < ::Mail::Ruby19::BestEffortCharsetEncoder
    def encode(string, charset)
      if charset.present? && charset.to_s.casecmp("iso-2022-jp") == 0
        # treated string as CP50221 (Microsoft Extended Encoding of ISO-2022-JP)
        # NKF.nkf("-w", string)
        string.force_encoding(Encoding::CP50221)
      else
        super
      end
    end
  end

  class ImapPool
    include MonitorMixin

    attr_reader :pool

    def initialize
      super()
      @pool = {}
    end

    def borrow(host:, account:, port: nil, timeout: nil)
      key = "#{host}:#{port || Net::IMAP.default_port}:#{account}"
      conn = synchronize { pool[key] ||= Net::IMAP.new(host, port: port) }

      Timeout.timeout(timeout || SS.config.webmail.imap_timeout) do
        yield conn
      end
    end

    def disconnect_all
      synchronize do
        pool.values.each do |conn|
          conn.logout rescue nil
          conn.disconnect rescue nil
        end
        pool.clear
      end
    end
  end

  module_function

  def activate_cp50221
    save = ::Mail::Ruby19.charset_encoder
    ::Mail::Ruby19.charset_encoder = Webmail.cp50221_encoder

    begin
      yield
    ensure
      ::Mail::Ruby19.charset_encoder = save
    end
  end

  def cp50221_encoder
    @cp50221_encoder ||= CP50221Encoder.new
  end

  def imap_pool
    @imap_pool ||= ImapPool.new
  end

  def find_webmail_quota_used(opts = {})
    Webmail.webmail_db_used(opts) + Webmail.webmail_files_used(opts)
  end

  MODULES = %w(
    Webmail::AddressGroup
    Webmail::Address
    Webmail::Filter
    Webmail::Group
    Webmail::History
    Webmail::History::ArchiveFile
    Webmail::Mail
    Webmail::Mailbox
    Webmail::Quota
    Webmail::Role
    Webmail::Signature
    Webmail::User
  ).freeze

  COMMON_MODULES = %w(
    Webmail::Group
    Webmail::User
  ).freeze

  def webmail_db_used(opts = {})
    classes = MODULES
    if opts[:except] == "common"
      classes = classes.reject { |klass| COMMON_MODULES.include?(klass) }
    end
    classes.map(&:constantize).sum { |klass| klass.all.unscoped.total_bsonsize }
  end

  def webmail_files_used(_opts = {})
    size = SS::File.where(model: /^webmail\//).aggregate_files_used

    dir = "#{Rails.root}/private/files/webmail_files"
    return size unless ::File.exist?(dir)

    # see: https://myokoym.hatenadiary.org/entry/20100606/1275836896
    ::Dir.glob("#{dir}/**/*") do |path|
      size += ::File.stat(path).size rescue 0
    end

    size
  end

  def text_to_html(text)
    return text if text.blank?

    text = ApplicationController.helpers.sanitize(text)
    text = ERB::Util.h(text)
    text = text.split(/\R\R+/).map { |t| "<p>#{t}</p>" }.join
    text = text.gsub(/\R/, '<br />')
    text
  end

  def html_to_text(html)
    return html if html.blank?

    fragment = Nokogiri::HTML.fragment(html.gsub(/<br.*?>/, "\n").gsub(/<hr.*?>/, "\n"))
    fragment.text
  end

  def reply_text(text, send_date:, from:, sign: nil)
    ret = "\n\n"
    ret += "#{I18n.l(send_date, format: :long)}, #{from}:\n"
    ret += text.to_s.gsub(/^/m, '> ')

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

  def reply_html(html, send_date:, from:, sign: nil)
    ret = <<~HTML
      <figure style="#{FIGURE_STYLE};">
        <figcaption>
          <time datetime="#{send_date.iso8601}">#{I18n.l(send_date, format: :long)}</time>
          <cite>#{from}</cite>
          :
        </figcaption>
        <blockquote style="#{QUOTE_STYLE};">
          #{html}
        </blockquote>
      </figure>
    HTML

    if sign
      ret += text_to_html(sign)
    end

    ret
  end

  def forward_text(text, subject:, send_date:, from:, sign: nil)
    ret = "\n\n"
    ret += "-------- #{I18n.t("gws/memo/message.forward_message_header")} --------\n"
    header = I18n.t("mongoid.attributes.gws/model/memo/message.subject")
    ret += "#{header}: #{subject}\n"
    header = I18n.t("mongoid.attributes.gws/model/memo/message.send_date")
    ret += "#{header}: #{I18n.l(send_date, format: :long)}\n"
    header = I18n.t("mongoid.attributes.gws/model/memo/message.from")
    ret += "#{header}: #{from}\n"
    ret += "\n\n"
    ret += "#{I18n.l(send_date, format: :long)}, #{from}:\n"
    ret += text.to_s.gsub(/^/m, '> ')

    if sign
      ret += "\n\n#{sign}"
    end

    ret
  end

  def forward_html(html, subject:, send_date:, from:, sign: nil)
    ret = <<~HTML
      -------- #{I18n.t("gws/memo/message.forward_message_header")} --------<br>
      <table>
        <tbody>
          <tr>
            <th scope="row">#{I18n.t("mongoid.attributes.gws/model/memo/message.subject")}</th>
            <td>#{subject}</td>
          </tr>
          <tr>
            <th scope="row">#{I18n.t("mongoid.attributes.gws/model/memo/message.send_date")}</th>
            <td><time datetime="#{send_date.iso8601}">#{I18n.l(send_date, format: :long)}</time></td>
          </tr>
          <tr>
            <th scope="row">#{I18n.t("mongoid.attributes.gws/model/memo/message.from")}</th>
            <td>#{from}</td>
          </tr>
        </tbody>
      </table>
      <br>
      #{html}
    HTML

    if sign
      ret += text_to_html(sign)
    end

    ret
  end
end
