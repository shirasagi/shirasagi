module Webmail
  extend Sys::ModulePermission

  class CP50221Encoder < Mail::Ruby19::BestEffortCharsetEncoder
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

    def borrow(host:, port:, account:)
      key = "#{host}:#{port || Net::IMAP.default_port}:#{account}"
      conn = synchronize { pool[key] ||= Net::IMAP.new(host, port: port) }

      Timeout.timeout(10) do
        yield conn
      end
    end

    def disconnect_all
      synchronize do
        pool.values.each do |conn|
          conn.disconnect
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
end
