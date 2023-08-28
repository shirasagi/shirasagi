module Kana::Converter
  @mecab = nil

  if SS.config.kana.disable == false
    require "MeCab"
    @mecab = MeCab::Tagger

    #require "natto"
    #@@mecab = Natto::MeCab
  end

  class << self
    def kana_html(site, html)
      return html unless @mecab

      config = SS.config.kana["converter"]
      kana_marks = config['kana-marks']
      skip_marks = config['skip-marks']
      html = html.tr("\u00A0", " ")

      text = html.gsub(/[\r\n\t]/, " ")
      text.gsub!(/<!--[^>]*?\s#{kana_marks[1]}\s[^>]*?-->.*?<!--[^>]*?\s#{kana_marks[0]}\s[^>]*?-->/im) do |m|
        "\r" * m.bytes.length
      end
      text.gsub!(/.*?<!--[^>]*?\s#{kana_marks[0]}\s[^>]*?-->/im) do |m|
        "\r" * m.bytes.length
      end
      text.gsub!(/<!--[^>]*?\s#{kana_marks[1]}\s[^>]*?-->.*/im) do |m|
        "\r" * m.bytes.length
      end
      tags = %w(head ruby script style)
      text.gsub!(/<!\[CDATA\[.*?\]\]>/m) { |m| mpad(m) }
      text.gsub!(/<!--.*?-->/m) { |m| mpad(m) }
      tags.each { |t| text.gsub!(/<#{t}( [^>]*\/>|[^\w].*?<\/#{t}>)/m) { |m| mpad(m) } }
      text.gsub!(/<.*?>/m) do |m|
        mpad(m).gsub(/\s*=\s*['"]([^'"]*)['"]/im) do |m|
          "\r" * m.bytes.length
        end
      end
      text.gsub!(/\\u003c.*?\\u003e/m) { |m| mpad(m) } #<>
      text.gsub!(/<!--[^>]*?\s#{skip_marks[0]}\s[^>]*?-->(.*?)<!--[^>]*?\s#{skip_marks[1]}\s[^>]*?-->/im) do |m|
        "\r" * m.bytes.length
      end
      text.gsub!(/[ -\/:-@\[-`{-~]/m, "\r")

      byte = html.bytes
      kana = ""
      pl   = 0
      retry_limit = 5

      Kana::Dictionary.pull(site.id) do |userdic|
        mecab_param = '--node-format=%ps,%pe,%m,%H\n --unk-format='
        if userdic.present?
          mecab_param = "-u #{userdic} " + mecab_param
        end
        mecab = @mecab.new(mecab_param)
        # https://taku910.github.io/mecab/format.html

        mecab.parse(text).split(/\n/).each do |line|
          next if line == "EOS"
          data = line.split(",")
          next if data[2] !~ /[一-龠a-zA-Z]/
          next if data[10].blank?

          ps = data[0].to_i
          pe = data[1].to_i
          if byte[ps..pe-1].pack("C*").force_encoding("utf-8") != data[2]
            retry_limit.times do
              byte.unshift(0)
              break if byte[ps..pe-1].pack("C*").force_encoding("utf-8") == data[2]
            end
            raise Kana::ConvertError if byte[ps..pe-1].pack("C*").force_encoding("utf-8") != data[2]
          end
          kana << byte[pl..ps-1].pack("C*").force_encoding("utf-8") if ps != pl
          yomi = katakana_to_yomi(data[10].to_s, site.kana_format)
          kana << "<ruby>#{data[2]}<rp>(</rp><rt>#{yomi}</rt><rp>)</rp></ruby>"
          pl = pe
        end
      end

      kana << byte[pl..-1].pack("C*").force_encoding("utf-8")
      kana.scrub('').strip
    end

    private

    def mpad(str)
      str.gsub(/[^ -~]/, "   ")
    end

    def katakana_to_yomi(str, format)
      case format
      when "katakana"
        str
      when "romaji"
        require "romaji"
        Romaji.kana2romaji(str)
      else # hiragana
        str.tr("ァ-ン", "ぁ-ん")
      end
    end
  end
end
