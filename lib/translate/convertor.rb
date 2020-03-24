class Translate::Convertor
  attr_reader :site, :source, :target

  def initialize(site, source, target)
    @site = site
    @source = source
    @target = target
    @location = "#{site.translate_location.sub(/^\//, "")}/#{@target.code}"
  end

  def translatable?(text)
    return false if text =~ EmailValidator::REGEXP
    return false if text =~ /\A#{URI::regexp(%w(http https))}\z/
    return false if text =~ /\A[#{I18n.t("translate.ignore_character")}]+\z/
    true
  end

  def convert(html)
    return html if html.blank?

    if html =~ /<html.*>/m
      partial = false
    else
      html = "<html><body>" + html + "</body></html>"
      partial = true
    end

    doc = Nokogiri.parse(html)

    # links
    regexp = /^#{@site.url}(?!#{@location}\/)(?!fs\/)/
    location = "#{@site.url}#{@location}/"
    doc.css('body a,body form').each do |node|
      href = node.attributes["href"].try(:value)
      action = node.attributes["action"].try(:value)

      if href.present? && href =~ /(\.html|\/)$/
        node.attributes["href"].value = href.gsub(regexp, location)
      end
      if action.present?
        node.attributes["action"].value = action.gsub(regexp, location)
      end
    end

    # notranslate
    doc.search('//*[contains(@class, \'notranslate\')]/descendant::*').each do |node|
      node.instance_variable_set(:@notranslate, true)
    end
    doc.search('//*[contains(@class, \'notranslate\')]/descendant::text()').each do |node|
      node.instance_variable_set(:@notranslate, true)
    end

    # exstract translate text
    nodes = []
    doc.search('//text()').each do |node|
      next if node.node_type != 3
      next if node.blank?
      next if node.instance_variable_get(:@notranslate)

      text = node.content.gsub(/[[:space:]]+/, " ").strip
      next if !translatable?(text)

      node.content = text
      nodes << node
    end
    doc.search('//input[@type][@value]').each do |node|
      type = node.attributes["type"]
      value = node.attributes["value"]

      next if type.content != "submit" && type.content != "reset"
      next if value.blank?
      next if node.instance_variable_get(:@notranslate)

      nodes << value
    end

    item = Translate::RequestBuffer.new(@site, @source, @target)
    nodes.each do |node|
      text = node.content
      item.push text, node
    end
    item.translate.each do |node, caches|
      node.content = caches.map { |caches| caches.text }.join("\n")
    end

    if partial
      html = doc.css("body").inner_html
      html.delete!("<html>", "")
      html.delete!("</html>", "")
    else
      html = doc.to_s
      html.sub!(/(<html.*?)lang="#{@source.code}"/, "\\1lang=\"#{@target.code}\"")
      html.sub!(/<body( |>)/m, '<body data-translate="' + @target.code + '"\\1')
      html.sub!(/<\/head>/, '<meta name="google" value="notranslate">' + "</head>")
    end

    html
  end
end
