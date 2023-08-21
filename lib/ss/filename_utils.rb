class SS::FilenameUtils
  FILESYSTEM_AND_URL_SAFE_CHARS = begin
    # see: https://www.ietf.org/rfc/rfc3986.txt
    rfc3986_unreserved = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a + %w(- . _ ~)
    rfc3986_sub_delims = %w(! $ & ' ( ) * + , ; =)
    rfc3986_strict_pchar = rfc3986_unreserved + rfc3986_sub_delims + %w(: @)

    # カンマとセミコロンが利用できないのは随分と前の Windows。現在は問題ないようだ。
    # filesystem_unsafe_chars = %w(\\ / : , ; * ? " < > |)
    filesystem_unsafe_chars = %w(\\ / : * ? " < > |)

    codes = rfc3986_strict_pchar - filesystem_unsafe_chars

    # space(' ') is not on url safe, but it is worth to support
    codes << ' '

    # "&" -> "&amp;" のように変化する文字を除外する。
    # HTML 内にリンクURLとしてセットされると、"&" -> "&amp;" のように変化してしまう。
    # このように変化したのを知らずリンクURLを置換しようとして、マッチせず、置換に失敗してしまう場合がある。
    codes.select! { |code| CGI.escapeHTML(code) == code }

    codes.sort!
    codes.map!(&:freeze)
    codes
  end.freeze
  FILESYSTEM_AND_URL_SAFE_SYMBOLS = begin
    codes = FILESYSTEM_AND_URL_SAFE_CHARS.dup
    codes -= ('0'..'9').to_a
    codes -= ('A'..'Z').to_a
    codes -= ('a'..'z').to_a
    # codes << "＿".freeze
    codes.delete(".")
    codes.delete("(")
    codes.delete(")")
    codes
  end.freeze

  # 連続する記号にマッチする正規表現（一つにまとめる目的で利用する）
  RE1 = /(#{FILESYSTEM_AND_URL_SAFE_SYMBOLS.map { |s| ::Regexp.escape(s) }.join("|")})+/.freeze
  # 先頭の連続する記号にマッチする正規表現（削除する目的で利用する）
  RE2 = /^(#{FILESYSTEM_AND_URL_SAFE_SYMBOLS.map { |s| ::Regexp.escape(s) }.join("|")})+([^.])/.freeze
  # 末尾の連続する記号にマッチする正規表現（削除する目的で利用する）
  RE3 = /([^.])(#{(FILESYSTEM_AND_URL_SAFE_SYMBOLS - [")"]).map { |s| ::Regexp.escape(s) }.join("|")})+$/.freeze
  # ピリオド直前の連続する記号にマッチする正規表現（削除する目的で利用する）
  RE4 = /([^.])(#{(FILESYSTEM_AND_URL_SAFE_SYMBOLS - [")"]).map { |s| ::Regexp.escape(s) }.join("|")})+\./.freeze

  NON_ASCII_RE = /[^\w\-.]/.freeze

  attr_accessor :duplicate_filenames

  def initialize
    @duplicate_filenames = []
  end

  def format_duplicates(filename)
    while @duplicate_filenames.include?(filename)
      extname = ::File.extname(filename)
      filename = filename.sub(/( \((\d+)\))?#{extname}$/) do
        index = $2.to_i
        index += 1
        " (#{index})#{extname}"
      end
    end
    @duplicate_filenames << filename
    filename
  end

  class << self
    def convert_by_sequence(filename, opts)
      return filename unless NON_ASCII_RE.match?(filename)
      id = opts[:id]
      "#{id}#{::File.extname(filename)}"
    end

    def convert_by_underscore(filename, _opts = nil)
      filename.gsub(NON_ASCII_RE, "_")
    end

    def convert_by_hex(filename, _opts = nil)
      "#{SecureRandom.hex(16)}#{::File.extname(filename)}"
    end

    if Rails.env.test?
      def convert(filename, options)
        send("convert_by_#{SS.config.env.multibyte_filename}", filename, options)
      end
    else
      case SS.config.env.multibyte_filename
      when "sequence"
        alias convert convert_by_sequence
      when "hex"
        alias convert convert_by_hex
      else
        alias convert convert_by_underscore
      end
    end

    def make_tmpname(prefix = nil, suffix = nil)
      # blow code come from Tmpname::make_tmpname
      "#{prefix}#{Time.zone.now.strftime("%Y%m%d")}-#{$PID}-#{rand(0x100000000).to_s(36)}#{suffix}"
    end

    def normalize(str)
      return if str.nil?
      str.unicode_normalize(SS.config.env.unicode_normalization_method || :nfkc)
    end

    # 半角の場合、アルファベットと数字と "-" と "_" とスペースのみを使用可。それ以外はアウト。
    # 全角の場合、Shift_JIS のコード表（ただし機種依存文字を除く）に記載のある文字ならセーフ、それ以外ならアウト
    def url_safe_japanese?(str)
      str.each_char.all? { |ch| url_safe_japanese_char?(ch) }
    end

    def convert_to_url_safe_japanese(str)
      chars = normalize(str).each_char.map do |ch|
        next ch if url_safe_japanese_char?(ch)

        norm_ch = normalize(ch)
        next norm_ch if url_safe_japanese_char?(norm_ch)

        # ch がファイルシステムセーフで URL セーフな記号の場合、"_" へ置換するのではなくて全角へ変換するという案も考えられた。
        # この案を試すことなく納得感のある正規化が得られたので、この案は試していない。

        ch.ord <= 0x7f ? "_" : "＿"
      end

      ret = chars.join

      #
      # 様々な案件を考慮して、なんとなく納得感のある正規化を ret に対して実施する。
      # 以下の正規化は多分にヒューリスティクスを含んでいて、全員を満足させられないかもしれない。
      #

      # 連続するアンダースコアは一つにまとめる
      ret.gsub!(RE1) { |matched| matched.first }
      # 先頭や末尾にアンダースコアがあると醜いので消す
      ret.sub!(RE2, '\2')
      ret.sub!(RE3, '\1')
      ret.sub!(RE4, '\1.')

      ret
    end

    private

    def url_safe_japanese_char?(utf8_char)
      if utf8_char.ord <= 0x7f
        return true if FILESYSTEM_AND_URL_SAFE_CHARS.bsearch { |x| utf8_char <=> x }
        false
      else
        begin
          utf8_char.encode('sjis')
          # sjis への変換に成功すれば safe とみなす。
          true
        rescue EncodingError
          # sjis への変換に失敗すれば unsafe とみなす。
          false
        end
      end
    end
  end
end
