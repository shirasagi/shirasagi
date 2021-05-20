def create_cms_layout(*parts)
  parts.flatten!
  options = parts.extract_options!
  html = []
  html << "<html><body><br><br><br>"
  if options.delete(:page_name)
    html << "<h1 id=\"ss-page-name\">\#{page_name}</h1><br>"
  end
  html << "<div id=\"main\" class=\"page\">"
  html << parts.map { |m| '{{ part "/' + m.filename.sub(/\..*/, '') + '" }}' }.join("\n")
  html << "{{ yield }}"
  html << "</div></body></html>"
  create :cms_layout, options.merge(html: html.join)
end
