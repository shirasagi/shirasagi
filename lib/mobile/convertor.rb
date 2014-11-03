class Mobile::Convertor < String
  @@tags = {
    remove: %w(
      area audio canvas caption col colgroup embed iframe keygen map noscript
      object optgroup output param progress script source track video),
    strip: %w(
      command datalist link rp rt style tbody tfoot thead),
    div: %w(
      article aside figure footer header nav section),
    span: %w(
      abbr address b bdi bdo code del detail dfn em fieldset figcaption figure hgroup i ins kbd
      label legend mark menu meter ruby s samp small strong sub summary sup time u var)
  }

  public
    def convert!
      downcase_tags!
      remove_comments!
      remove_cdata_sections!
      remove_other_namespace_tags!
      remove_convert_tags!
      strip_convert_tags!
      gsub_convert_tags!
      gsub_img!
      gsub_q!
      gsub_wbr!
      gsub_br!
    end

  private
    def s_to_attr(str)
      str.scan(/\S+?=".+?"/m).
        map { |s| s.split(/=/).size == 2 ? s.gsub(/"/, "").split(/=/) : nil }.
        compact.to_h
    end

    def attr_to_s(attr)
      attr.map { |k, v| "#{k}=\"#{v}\"" }.join(" ")
    end

    def gsub_tag!(src_tag, dst_tag)
      self.gsub!(/<(\/?)#{src_tag}>/m) do
        head = $1
        dst_tag.present? ? "<#{head}#{dst_tag}>" : ""
      end

      self.gsub!(/<#{src_tag} (.*?)(\/?)>/m) do
        src_attr = s_to_attr $1.to_s
        dst_attr = {}
        tail = $2

        if dst_tag.present?
          dst_attr["id"]    = src_attr["id"] if src_attr["id"]
          dst_attr["class"] = "tag-#{src_tag}" + ( src_attr["class"] ? " #{src_attr['class']}" : "" )
          yield src_attr, dst_attr if block_given?

          "<#{dst_tag} #{attr_to_s(dst_attr)}#{tail}>"
        else
          ""
        end
      end
    end

    def remove_tag!(tag)
      gsub!(/<#{tag}[ >].*?<\/#{tag}>/m, "")
      gsub_tag!(tag, "")
    end

    def remove_convert_tags!
      @@tags[:remove].each { |tag| remove_tag!(tag) }
    end

    def strip_convert_tags!
      @@tags[:strip].each { |tag| gsub_tag!(tag, "") }
    end

    def gsub_convert_tags!
      @@tags[:div].each  { |tag| gsub_tag!(tag, "div")  }
      @@tags[:span].each { |tag| gsub_tag!(tag, "span") }
    end

    def gsub_img!
      self.gsub!(/<img(.*?)\/?>/) do |match|
        src_attr = s_to_attr $1.to_s
        dst_attr ={}
        ext = File.extname(src_attr["src"].to_s).downcase

        if ext =~ /^\.(jpeg|jpg|bmp)$/
          href = src_attr["src"].presence
          name = src_attr["alt"].presence || src_attr["title"].presence || href.sub(/.*\//, "")
          cls  = "tag-img" + ( src_attr["class"] ? " #{src_attr['class']}" : "" )

          html  = name
          html += %( <a href="#{href}" class="#{cls}" title="#{name}">[#{I18n.t("views.image")}]</a>) if href
          html
        else
          match
        end
      end
    end

    def gsub_q!
      self.gsub!("<q>", "\"")
      self.gsub!("</q>", "\"")
    end

    def gsub_wbr!
      self.gsub!("<wbr>", "<br />")
      self.gsub!("<wbr />", "<br />")
    end

    def gsub_br!
      self.gsub!("<br/>", "<br />")
      self.gsub!("<br>", "<br />")
    end

    def remove_other_namespace_tags!
      self.gsub!(/<\S*?\:\S*?.*?>/m, "")
    end

    def remove_comments!
      self.gsub!(/<!--.*?-->/m, "")
    end

    def remove_cdata_sections!
      self.gsub!(/<!\[CDATA\[.*?\]\]>/m, "")
    end

    def downcase_tags!
      self.gsub!(/<(\/?)([A-Z]+)(.*?)(\/?)>/m) do
        ele  = $2
        src_attr = s_to_attr $3.to_s
        dst_attr = {}
        head = $1
        tail = $4

        src_attr.each { |k, v| dst_attr[k.downcase] = v }
        if dst_attr.present?
          "<#{head}#{ele.downcase} #{attr_to_s(dst_attr)} #{tail}>"
        else
          "<#{head}#{ele.downcase}#{tail}>"
        end
      end
    end
end
