require 'nokogiri'

class Voice::Scraper
  public
    def initialize(config = {})
      @config = SS.config.voice["scraper"].merge(config)
      @voice_marks = @config["voice-marks"]
      @skip_marks = @config["skip-marks"]
      @delete_tags = @config["delete-tags"]
      @kuten_tags = @config["kuten-tags"]
    end

    def extract_text(html)
      # extract main chunk
      html = extract_body(html)

      # delete unnecessary chunk
      if html =~ /<!--[^>]*?\s#{@skip_marks[0]}\s[^>]*?-->/i
        html.gsub!(/<!--[^>]*?\s#{@skip_marks[0]}\s[^>]*?-->(.*)<!--[^>]*?\s#{@skip_marks[1]}\s[^>]*?-->/im, '')
      end
      html.gsub!(/<\s*(#{@delete_tags.join("|")})\s*>.*?<\/\s*\1\s*>/im, '')

      # <img> tag's special case
      html.gsub!(/<\s*img[^>]*>/im) do |m|
        m =~ /(title|alt)\s*=\s*['"]([^'"]*)['"]/im ? "画像 #{$2}" : nil
      end

      html.gsub!(/<\/\s*(#{@kuten_tags.join("|")})\s*>/i, "\n")
      html.gsub!(/<\s*(#{@kuten_tags.join("|")})\s*\/>/i, "\n")
      html.gsub!(/<\/?[a-z!][^>]*?>/i, "")

      html = CGI::unescapeHTML(html)
      html.gsub!("&nbsp;", " ")
      html.gsub!(/\s*。+\s*/, "。")
      html.gsub!(/。+/, "。")
      # html.tr!('０-９ａ-ｚＡ-Ｚ', '0-9a-zA-Z')

      texts = html.split(/\r?\n/).map do |line|
        line.gsub!(/[[:cntrl:]　]+/, " ")
        line.chomp!
        line.strip!
        line.gsub!(/\s+/, " ")
        line
      end
      texts.select do |line|
        line.length > 0
      end
    end

  private
    def extract_body(html)
      if html =~ /<!--[^>]*?\s#{@voice_marks[0]}\s[^>]*?-->(.*)<!--[^>]*?\s#{@voice_marks[1]}\s[^>]*?-->/im
        $1
      elsif html =~ /<\s*body[^>]*>(.*)<\/\s*body\s*>/im
        $1
      else
        html.clone
      end
    end

    DEFAULT_INSTANCE = self.new
end
